import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lejutv/components/focus_icon_button.dart';
import 'package:lejutv/model/channel.dart';
import 'package:lejutv/stores/channel.storage.dart';

class ChannelManagerDialog extends StatefulWidget {
  const ChannelManagerDialog({
    required this.address,
    required this.channels,
    required this.onChanged,
    super.key,
  });

  final String address;
  final List<Channel> channels;
  final Future<void> Function() onChanged;

  @override
  State<ChannelManagerDialog> createState() => _ChannelManagerDialogState();
}

class _ChannelManagerDialogState extends State<ChannelManagerDialog> {
  final nameController = TextEditingController();
  final urlController = TextEditingController();
  late List<Channel> channels;
  String message = '';

  @override
  void initState() {
    super.initState();
    channels = [...widget.channels];
  }

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final value = await ChannelStorage.instance.getChannels();
    if (!mounted) return;
    setState(() => channels = value);
    await widget.onChanged();
  }

  Future<void> add() async {
    final name = nameController.text.trim();
    final url = urlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() => message = '请输入频道名称和 URL');
      return;
    }
    final added = await ChannelStorage.instance.addChannel(
      Channel(name: name, url: url),
    );
    if (!added) {
      setState(() => message = '该 URL 已存在');
      return;
    }
    nameController.clear();
    urlController.clear();
    setState(() => message = '已新增频道');
    await refresh();
  }

  Future<void> restoreDefaults() async {
    await ChannelStorage.instance.restoreDefaults();
    setState(() => message = '已恢复默认频道');
    await refresh();
  }

  Future<void> delete(Channel channel) async {
    await ChannelStorage.instance.deleteChannel(channel.url);
    setState(() => message = '已删除 ${channel.name}');
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff17202d),
      title: const Text('频道管理', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: math.min(MediaQuery.sizeOf(context).width * .84, 620),
        height: math.min(MediaQuery.sizeOf(context).height * .72, 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '局域网管理地址：${widget.address}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '名称',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: add,
                  icon: const Icon(Icons.add, color: Colors.cyanAccent),
                  tooltip: '新增',
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${channels.length} 个频道',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                TextButton(
                  onPressed: restoreDefaults,
                  child: const Text('恢复默认'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: channels.length,
                itemBuilder: (_, index) {
                  final channel = channels[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      channel.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      channel.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: FocusIconButton(
                      icon: Icons.delete_outline,
                      onPressed: () => delete(channel),
                      tooltip: '删除',
                    ),
                  );
                },
              ),
            ),
            if (message.isNotEmpty)
              Text(
                message,
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
