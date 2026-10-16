import 'package:flutter/material.dart';
import 'package:lejutv/components/nav_next_button.dart';
import 'package:lejutv/components/source_card_button.dart';
import 'package:lejutv/page/douyin_page.dart';
import 'package:lejutv/page/kuaishou_page.dart';
import 'package:lejutv/page/tv_page.dart';
import 'package:lejutv/components/focus_icon_button.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  static const background = Color(0xFF111415);
  static const panel = Color(0xFF1A1D1E);
  static const green = Color(0xFF00C878);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StartPage.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 24),
          child: Column(
            children: [
              Row(
                children: [
                  NavTextButton(label: '视频', autofocus: true, onTap: () {}),
                  const SizedBox(width: 34),
                  NavTextButton(
                    label: '电视',
                    onTap: () => _open(context, const TvPage()),
                  ),
                  const Spacer(),
                  FocusIconButton(
                    tooltip: '收藏',
                    onPressed: () {},
                    icon: Icons.favorite_border,
                    iconSize: 26,
                  ),
                  FocusIconButton(
                    tooltip: '搜索',
                    onPressed: () {},
                    icon: Icons.search,
                    iconSize: 28,
                  ),
                  FocusIconButton(
                    tooltip: '设置',
                    onPressed: () {},
                    icon: Icons.settings_outlined,
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 78),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VIDEO HUB',
                            style: TextStyle(
                              color: StartPage.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '视频',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 18,
                            runSpacing: 18,
                            children: [
                              SourceCardButton(
                                title: '抖音',
                                subtitle: '热门短视频与精彩内容',
                                icon: '音',
                                accent: const Color(0xFF292B2D),
                                onTap: () => _open(context, const DouyinPage()),
                              ),
                              SourceCardButton(
                                title: '快手',
                                subtitle: '发现真实有趣的生活',
                                icon: '快',
                                accent: const Color(0xFFFF4F31),
                                onTap: () =>
                                    _open(context, const KuaishouPage()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '精选内容 · 随时观看',
                    style: TextStyle(
                      color: Color(0xFF5D6365),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'LeJu TV',
                    style: TextStyle(
                      color: Color(0xFF5D6365),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
