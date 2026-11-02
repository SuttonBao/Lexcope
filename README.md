# Lexcope

面向 iPhone / iPad 的离线背单词应用，支持 iOS 17 及以上版本。

词卡只展示单词和音标：点击看详情，点击音标听读音，右滑认识、左滑不认识、下滑模糊，按间隔重复计划复习。

## V1 功能

- 生活核心词、PTE 学术入门、IELTS 学术入门、常用短语，共 60 个起始词条；词集可多选，重叠词共享进度。
- UTF-8 CSV / JSON 文件导入，校验与预览后保存，支持自定义单词与短语。
- 中文、英英解释、例句、构词提示、常见搭配、同族词；未提供的内容明确留空。
- Apple 系统英语朗读，可选英式 / 美式语音；内置音标为英式。
- 三方向评分、撤销、VoiceOver 操作、可选评分按钮、动态字体和深浅色适配。
- 到期优先、每日新词额度、本地持久化、每日提醒、未来七天复习安排。

“认识”按 1、2、4、7、15、30 个自然日递进，此后每 30 天巩固；“不认识”重置阶段，5 分钟后重学；“模糊”回退一级，10 分钟后重学。这是受遗忘曲线启发的启发式规则，不承诺预测个人记忆率。次日复习从当地午夜到期，并非严格间隔 24 小时。

## 在 Xcode 运行

1. 安装 **Xcode 16 或更新版本**（需要支持 Swift 6 的工具链和 iOS SDK）。
2. 打开 `Lexcope.xcodeproj`，选择 `Lexcope` scheme 和 iPhone / iPad 模拟器，按 ⌘R。
3. 真机运行时，在 Signing & Capabilities 选择你的 Apple Development Team，并按需修改 Bundle Identifier。模拟器无需开发者签名。
4. 首次启动进入“词集”，勾选想学的词集，回到“今日”开始记忆。
5. 在“设置”保存每日新词额度、英语语音和可选提醒。

没有 Xcode 时也可用 Swift 6 命令行工具运行核心测试：

```sh
Scripts/test.sh
Scripts/check_ui.sh
```

第二个脚本使用 macOS SDK 对共享 SwiftUI 页面做类型检查，并运行实际 AppModel / 文件存储集成验证；它不替代 iOS 编译或模拟器测试。脚本将编译缓存写入临时目录，兼容仅安装 Command Line Tools 的机器。

完整 iOS UI 测试：Xcode 中按 ⌘U，或运行：

```sh
xcodebuild -project Lexcope.xcodeproj -scheme Lexcope \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
```

将设备名替换为本机已安装的模拟器。CI 自动选择可用 iPhone，执行构建及手势、详情、发音入口、撤销、重启持久化的 UI 冒烟测试，并保存 xcresult。

## 导入自己的词集

在“词集”点击“+”，从“文件”选择 CSV 或 JSON，查看预览后点击“导入并选用”。

- 每次 1–5000 词，最大 2 MB，UTF-8 编码。
- `term` 与 `meaning` 必填；音标和详情可选。缺失音标时仍可点击发音，不会生成未经核验的 IPA。
- CSV 可选字段：`ipa,definition,example,example_chinese,etymology,collocations,family`。搭配和词族用 `|` 分隔。
- JSON 使用 `title` 和 `words`；`examples` 为含 `english`、`chinese` 的对象数组，搭配和词族为字符串数组。
- 词集内不允许大小写不敏感的重复词。导入已有单词时复用原词条与进度，不覆盖释义。
- 文件全部校验通过并成功保存后才加入词库。

可直接使用 [CSV 示例](Examples/my-words.csv) 和 [JSON 示例](Examples/my-words.json)。

## 项目结构

```text
App/                    SwiftUI 页面、语音、提醒、UI 状态
Sources/LexcopeCore/    模型、存储、调度、队列、导入、内置词库
Tests/                  Swift 核心测试
IntegrationTests/       实际 AppModel 与磁盘故障集成验证
UITests/                原生 iPhone UI 冒烟测试
Scripts/                工程生成、词库重建、测试、图标绘制
Lexcope.xcodeproj/      可直接打开的 Xcode 工程
```

新增 App 文件后运行 `python3 Scripts/generate_project.py`。重建内置内容运行 `python3 Scripts/build_vocabulary.py`。不需要额外安装工程生成工具或第三方依赖。

## 内容、隐私与当前边界

内置词表来源与许可见 [内容来源](docs/CONTENT_SOURCES.md)。NGSL / NAWL 原始词表和词库学习内容采用 CC BY-SA 4.0，保留作者署名；应用代码尚未指定开源许可。PTE / IELTS 是备考入门编排，非官方或完整考试词库。原创释义、音标仍需发布前的词典编辑校订；历史词源尚未完整补齐。

无需账号，无广告和分析 SDK，学习记录保存在应用 Application Support 的 `Lexcope/state.json`。系统语音资源可能需要事先下载。提醒由设备本地调度。V1 不含云同步、应用内备份恢复、付费、正式考试完整词库或 App Store 发布。卸载可能移除本地进度。

[开发计划](docs/PLAN.md) · [验收记录](docs/VALIDATION.md) · [GitHub Actions](https://github.com/SuttonBao/Lexcope/actions)
