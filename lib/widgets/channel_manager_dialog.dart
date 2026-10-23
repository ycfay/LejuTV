import 'dart:math' as math;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late List<Channel> channels;
  final FocusScopeNode _dialogFocusScope = FocusScopeNode(
    debugLabel: 'channel-manager-dialog',
  );

  @override
  void initState() {
    super.initState();
    channels = [...widget.channels];
  }

  @override
  void dispose() {
    _dialogFocusScope.dispose();
    super.dispose();
  }

  KeyEventResult onDialogKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.backspace) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> refresh() async {
    final value = await ChannelStorage.instance.getChannels();
    if (!mounted) return;
    setState(() => channels = value);
    await widget.onChanged();
  }

  Future<void> restoreDefaults() async {
    await ChannelStorage.instance.restoreDefaults();
    BotToast.showText(text: "已恢复默认频道");
    await refresh();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> delete(Channel channel) async {
    await ChannelStorage.instance.deleteChannel(channel.url);
    BotToast.showText(text: '删除成功 ${channel.name}');
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    void closeDialog() {
      if (mounted) Navigator.of(context).pop();
    }

    return PopScope<void>(
      // Android system-back may bypass the focused key handler. Keep the
      // dialog route from falling through to the TV page, then close this
      // dialog explicitly when that back gesture is received.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) Navigator.of(context).pop();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.goBack): closeDialog,
          const SingleActivator(LogicalKeyboardKey.escape): closeDialog,
          const SingleActivator(LogicalKeyboardKey.backspace): closeDialog,
        },
        child: FocusScope(
          node: _dialogFocusScope,
          autofocus: true,
          onKeyEvent: onDialogKey,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: AlertDialog(
              backgroundColor: const Color(0xff17202d),
              title: const Text('频道管理', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: math.min(MediaQuery.sizeOf(context).width * .84, 620),
                height: math.min(MediaQuery.sizeOf(context).height * .72, 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        '局域网管理地址：${widget.address}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
