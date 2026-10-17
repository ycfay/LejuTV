import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lejutv/model/channel.dart';
import 'package:lejutv/stores/channel.storage.dart';

/// Small LAN server used by the channel maintenance page.
class RemoteHttpServer {
  RemoteHttpServer({ChannelStorage? storage})
    : _storage = storage ?? ChannelStorage.instance;

  final ChannelStorage _storage;
  HttpServer? _server;
  String? _host;

  bool get isRunning => _server != null;
  String? get address => _server == null || _host == null
      ? null
      : 'http://$_host:${_server!.port}/';

  Future<String> start() async {
    if (_server != null) return address!;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: true);
    _host = await _findHost();
    _server!.listen(_handleRequest, onError: (_) {});
    return address!;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _host = null;
    await server?.close(force: true);
  }

  Future<String> _findHost() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return InternetAddress.loopbackIPv4.address;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/') {
        await _asset(
          request.response,
          'assets/remote/index.html',
          'text/html; charset=utf-8',
        );
        return;
      }
      if (request.method == 'GET' && path == '/app.css') {
        await _asset(
          request.response,
          'assets/remote/app.css',
          'text/css; charset=utf-8',
        );
        return;
      }
      if (request.method == 'GET' && path == '/app.js') {
        await _asset(
          request.response,
          'assets/remote/app.js',
          'application/javascript; charset=utf-8',
        );
        return;
      }
      if (request.method == 'GET' && path == '/api/channels') {
        final channels = await _storage.getChannels();
        return _json(request.response, {
          'channels': channels.map((channel) => channel.toJson()).toList(),
        });
      }
      if (request.method == 'POST' && path == '/api/channels') {
        final body = await _body(request);
        final name = body['name']?.toString().trim() ?? '';
        final url = body['url']?.toString().trim() ?? '';
        if (name.isEmpty || url.isEmpty) {
          return _json(request.response, {'error': '名称和 URL 不能为空'}, 400);
        }
        final added = await _storage.addChannel(Channel(name: name, url: url));
        return _json(request.response, {'added': added});
      }
      if (request.method == 'POST' && path == '/api/delete') {
        final body = await _body(request);
        final deleted = await _storage.deleteChannel(
          body['url']?.toString() ?? '',
        );
        return _json(request.response, {'deleted': deleted});
      }
      if (request.method == 'POST' && path == '/api/clear') {
        return _json(request.response, {
          'deleted': await _storage.clearChannels(),
        });
      }
      if (request.method == 'POST' && path == '/api/defaults') {
        return _json(request.response, {
          'restored': await _storage.restoreDefaults(),
        });
      }
      _text(request.response, 'Not found', 'text/plain; charset=utf-8', 404);
    } catch (error) {
      _json(request.response, {'error': error.toString()}, 500);
    }
  }

  Future<Map<String, dynamic>> _body(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    final value = jsonDecode(text);
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  void _json(HttpResponse response, Object body, [int status = 200]) {
    response.statusCode = status;
    response.headers
      ..contentType = ContentType.json
      ..set('Access-Control-Allow-Origin', '*');
    response.write(jsonEncode(body));
    response.close();
  }

  void _text(
    HttpResponse response,
    String body,
    String type, [
    int status = 200,
  ]) {
    response.statusCode = status;
    response.headers
      ..contentType = ContentType.parse(type)
      ..set('Access-Control-Allow-Origin', '*');
    response.write(body);
    response.close();
  }

  Future<void> _asset(HttpResponse response, String path, String type) async {
    final body = await rootBundle.loadString(path);
    _text(response, body, type);
  }
}

// ignore: unused_element
const _page =
    '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>乐聚频道管理</title><style>body{font:16px system-ui;margin:0;background:#10141c;color:#f5f7fb}main{max-width:760px;margin:auto;padding:24px}section{background:#1b2230;border:1px solid #303b4d;border-radius:12px;padding:18px;margin:14px 0}h1{margin:0 0 4px}input{box-sizing:border-box;width:100%;padding:11px;margin:5px 0 12px;border-radius:7px;border:1px solid #526078;background:#111722;color:white}button{padding:10px 14px;border:0;border-radius:7px;background:#147df5;color:white;cursor:pointer;margin-right:8px}.danger{background:#c94646}.row{display:flex;gap:12px;justify-content:space-between;border-top:1px solid #303b4d;padding:12px 0}.row small{display:block;color:#aab5c7;overflow-wrap:anywhere}</style></head><body><main><h1>频道管理</h1><p>在同一局域网的手机或电脑打开本页面即可维护频道。</p><section><h2>新增频道</h2><form id="add"><input id="name" required placeholder="频道名称"><input id="url" required placeholder="https://..."><button>新增</button></form></section><section><h2>频道列表 <span id="count"></span></h2><button id="restore">恢复默认</button><button id="clear" class="danger">删除全部</button><div id="list"></div></section><p id="msg"></p></main><script src="/app.js"></script></body></html>''';

// ignore: unused_element
const _script =
    '''const list=document.querySelector('#list'),count=document.querySelector('#count'),msg=document.querySelector('#msg');async function api(path,opt){const r=await fetch(path,opt);const j=await r.json();if(!r.ok)throw Error(j.error||r.status);return j}async function load(){const d=await api('/api/channels');count.textContent='('+d.channels.length+'个)';list.innerHTML='';d.channels.forEach(c=>{const row=document.createElement('div');row.className='row';row.innerHTML='<div><b></b><small></small></div><button class="danger">删除</button>';row.querySelector('b').textContent=c.name;row.querySelector('small').textContent=c.url;row.querySelector('button').onclick=async()=>{await api('/api/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({url:c.url})});msg.textContent='已删除';load()};list.append(row)})}document.querySelector('#add').onsubmit=async e=>{e.preventDefault();const ok=await api('/api/channels',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:name.value,url:url.value})});msg.textContent=ok.added?'已新增':'URL 已存在';e.target.reset();load()};restore.onclick=async()=>{await api('/api/defaults',{method:'POST'});msg.textContent='已恢复默认';load()};clear.onclick=async()=>{if(confirm('确定删除全部频道？')){await api('/api/clear',{method:'POST'});msg.textContent='已清空';load()}};load();''';
