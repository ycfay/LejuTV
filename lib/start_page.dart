import 'package:flutter/material.dart';
import 'package:lejutv/douyin_page.dart';
import 'package:lejutv/kuaishou_page.dart';
import 'package:lejutv/tv_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  static const background = Color(0xFF111415);
  static const panel = Color(0xFF1A1D1E);
  static const green = Color(0xFF00C878);

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 24),
          child: Column(
            children: [
              Row(
                children: [
                  _NavText(label: '视频', active: true),
                  const SizedBox(width: 34),
                  _NavText(
                    label: '直播',
                    onTap: () => _open(context, const TvPage()),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '收藏',
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border, size: 26),
                    color: Colors.white,
                  ),
                  IconButton(
                    tooltip: '搜索',
                    onPressed: () {},
                    icon: const Icon(Icons.search, size: 28),
                    color: Colors.white,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: green, width: 1.5),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: IconButton(
                      tooltip: '设置',
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined, size: 25),
                      color: Colors.white,
                    ),
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
                              color: green,
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
                              _SourceCard(
                                title: '抖音',
                                subtitle: '热门短视频与精彩内容',
                                icon: '音',
                                accent: const Color(0xFF292B2D),
                                onTap: () => _open(context, const DouyinPage()),
                              ),
                              _SourceCard(
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
                    'TV DEMO',
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

class _NavText extends StatelessWidget {
  const _NavText({required this.label, this.active = false, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF797E80),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: StartPage.panel,
          border: Border.all(color: const Color(0xFF2A2E2F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                icon,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8B9092),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '→',
              style: TextStyle(color: StartPage.green, fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }
}
