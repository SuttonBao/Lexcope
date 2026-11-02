# 项目协作规则

禁止批量删除文件或目录。不要使用 `del /s`、`rd /s`、`rmdir /s`、`Remove-Item -Recurse` 或 `rm -rf`。

创建 Git 分支时，不要以 `codex` 作为开头。每个任务使用独立分支，完成验证后提交，再合入 main。

## 开发

- iOS 17+ SwiftUI App，纯 Swift 核心模块，无第三方依赖。
- 核心测试：`Scripts/test.sh`。随后运行 `Scripts/check_ui.sh` 做 SwiftUI 类型检查与持久化集成验证。
- 新增 App Swift 文件后运行 `python3 Scripts/generate_project.py`。
- 词库从 `Scripts/build_vocabulary.py` 重建；保留来源与 CC BY-SA 4.0 署名。不要虚构词源或冒称官方考试词库。
- 保存成功后才能推进 UI。损坏的记录不得静默重置覆盖。
