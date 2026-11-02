# 内置内容与来源

V1 附带 **60 个完整注释的起始词条**，不是完整考试词库：

| 词集 | 数量 | 选词依据 |
| --- | ---: | --- |
| 生活核心词 | 24 | NGSL 1.2 摘选 |
| PTE 学术入门 | 16 | NAWL 1.2 的 Lexcope 备考编排 |
| IELTS 学术入门 | 16 | NAWL 1.2 的 Lexcope 备考编排 |
| 生活常用短语 | 12 | Lexcope 编写 |

两套考试入门词集有 8 个重叠词，学习进度共享。它们不由 Pearson、IELTS 或考试机构编写、认证或背书。词表提供选词依据，不代表本应用释义经过词表作者校订。

## 官方来源

Browne, C., Culligan, B., & Phillips, J. (2013). *The New General Service List / New Academic Word List*.

- NGSL 1.2：https://www.newgeneralservicelist.com/new-general-service-list
- NAWL 1.2：https://www.newgeneralservicelist.com/new-academic-word-list
- 原始 NGSL 数据：https://www.newgeneralservicelist.com/s/NGSL_12_stats.csv
- 原始 NAWL 数据：https://www.newgeneralservicelist.com/s/NAWL_12_alphabetized_description.txt
- 授权：https://creativecommons.org/licenses/by-sa/4.0/

于 2026-11-03 获取。原始文件保存在 `docs/sources`，原样保留其引用。原文件中旧 `.org` 地址是历史记录；当前官方来源使用 `.com`，参见官方 FAQ：https://www.newgeneralservicelist.com/faqs-4 。

## 修改与许可

原始词表采用 **Creative Commons Attribution-ShareAlike 4.0 International**。本应用摘选词目、重新编排词集，并为选词编写中文、英英学习释义、英式音标、例句、搭配和词族。选词内容、原创学习内容及其 JSON 数据同样以 CC BY-SA 4.0 提供；此许可不自动涵盖应用代码。

释义是供 V1 验证使用的学习内容，发布前仍需词典编辑校订。没有足够依据的历史词源保持空值；部分词条附有明确标注的构词/词族提示，不把记忆法写成历史词源。用户导入的内容来源显示为“用户导入”。

`python3 Scripts/build_vocabulary.py` 可从保留的来源重建词库，脚本自动核对每个单词属于对应 NGSL / NAWL 原始词表。

## 后续内容扩展

正式内容版本应扩充高频核心词、按主题及 CEFR 等级整理考试备考词集，并引入可合法再分发、经人工校对的双语词典。当前导入功能允许用户添加完整的个人词库。
