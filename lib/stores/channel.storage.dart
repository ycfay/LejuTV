import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lejutv/model/channel.dart';
import 'package:lejutv/stores/base.storage.dart';

class ChannelStorage {
  ChannelStorage._();

  static final ChannelStorage instance = ChannelStorage._();

  static const String _storageKey = 'tv_channels';
  static const String _selectedChannelIndexKey = 'tv_selected_channel_index';
  static const String _assetPath = 'assets/data/channels.json';

  int? getSelectedChannelIndex() {
    final storage = BaseStorage.instance;
    if (!storage.containsKey(_selectedChannelIndexKey)) return null;
    return storage.getInt(_selectedChannelIndexKey);
  }

  Future<bool> saveSelectedChannelIndex(int index) {
    return BaseStorage.instance.setInt(_selectedChannelIndexKey, index);
  }

  Future<List<Channel>> getChannels() async {
    final cached = BaseStorage.instance.getObject(_storageKey);
    final cachedChannels = _decodeChannels(cached);
    if (cachedChannels != null) {
      return cachedChannels;
    }

    final assetJson = await rootBundle.loadString(_assetPath);
    final channels = _decodeChannels(jsonDecode(assetJson));
    if (channels == null || channels.isEmpty) {
      throw const FormatException('频道列表为空或格式无效');
    }

    await BaseStorage.instance.setObject(
      _storageKey,
      channels.map((channel) => channel.toJson()).toList(growable: false),
    );
    return channels;
  }

  Future<bool> addChannel(Channel channel) async {
    final channels = await getChannels();
    if (channels.any((item) => item.url == channel.url)) return false;
    return _saveChannels([...channels, channel]);
  }

  Future<bool> deleteChannel(String url) async {
    final channels = await getChannels();
    final remaining = channels.where((item) => item.url != url).toList();
    if (remaining.length == channels.length) return false;
    return _saveChannels(remaining);
  }

  Future<int> clearChannels() async {
    final channels = await getChannels();
    if (channels.isEmpty) return 0;
    await _saveChannels(const []);
    return channels.length;
  }

  Future<int> restoreDefaults() async {
    final assetJson = await rootBundle.loadString(_assetPath);
    final channels =
        _decodeChannels(jsonDecode(assetJson)) ?? const <Channel>[];
    if (channels.isEmpty) return 0;
    await _saveChannels(channels);
    return channels.length;
  }

  Future<bool> _saveChannels(List<Channel> channels) {
    return BaseStorage.instance.setObject(
      _storageKey,
      channels.map((channel) => channel.toJson()).toList(growable: false),
    );
  }

  List<Channel>? _decodeChannels(Object? value) {
    if (value is! List) return null;

    try {
      return value
          .map((item) => Channel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on TypeError {
      return null;
    } on FormatException {
      return null;
    }
  }
}
