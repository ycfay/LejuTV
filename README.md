# 乐聚TV

乐聚是一款面向大众用户的多平台视频聚合应用，整合抖音、快手、斗鱼、哔哩哔哩及电视直播等内容资源，将不同平台的网络视频与直播内容统一整理为直观、易用的频道列表。 产品坚持操作简单、界面直观、打开即看的设计理念，降低用户使用门槛，让用户无需在多个应用之间频繁切换，即可快速找到自己喜欢的内容。 乐聚支持 Android TV、Android 手机及平板设备，提供统一、流畅、沉浸式的视听体验，让精彩内容触手可及。

# 核心能力
内置默认频道，安装后即可直接使用
支持遥控器和触摸屏、支持扫码

# 编程代码
本项目由 Codex AI 全程驱动开发！🤖 从功能实现到项目构建，基本全靠 AI 自动完成。欢迎大家体验使用、提交 Issue、提出建议，一起完善！

使用截图


播放与切台
打开后会直接进入频道播放界面。

正常播放

上 / 下键：切换频道
数字键：直接输入频道号
OK / 右键：打开右侧频道列表
频道列表

频道


## build
flutter build apk --target-platform android-arm,android-arm64 --split-per-abi

## release
flutter build apk --release --target-platform android-arm,android-arm64

