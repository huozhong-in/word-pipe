# 部署说明

## 新增包的方法可以选择不直接修改pubspec.yaml，使用以下命令

`dart pub add url_launcher` 或 `flutter pub add url_launcher`

`flutter pub run flutter_launcher_icons:main`

## TODO

- 提速方案：
  - [x] 查询结果加缓存
  - [ ] 迁移到国内主机
  - [ ] wasm实现marisa-trie
- 产品功能
  - [x] 用户名+密码方式注册，暂不提供找回密码
  - [x] 规划PUBSUB type/channel，增加多用户支持。eventType="prod/dev/test" channel="hash(user_uuid+pass)" 
  - [x] 注册需邀请码
  - [ ] 强制登录，匿名无法使用
  - [ ] 翻译（ChatGPT）。大模型背后的理解、推理能力也至关重要。
  - [ ] 聊天记录。加载最后50条。聊天记录的价值在哪，人们翻看回溯是为什么，能否提供有特色的聊天回顾功能，总结、提醒、标注、收藏？再利用、成就感
  - [ ] 新消息来后，底部增加提示，点击跳转
  - [ ] 语音对话
  - [ ] 角色扮演。在界面上设计几个典型的角色，老师、考官、同学、单词老师？如果是不同的上下文，建议做成多个聊天对象，放在左侧
  - [ ] 高亮机器人文字里的生词。出题，造句
  - [ ] 机器人发送卡片
  - [ ] 桌面版本必须能在线更新
- 单词本/生词本
  - [ ] 导入。提供界面方式+开放插件方式让用户导入生词本，标注每个生词的。怎么借助ChatGPT把生词本玩出花来？
  - [ ] 导出。文本、CSV、PDF和anki connect
  - [ ] 造句。
  - [ ] 出题。
- 命令行增强和配置项
  - [x] 查找词根词缀，用template方式组合发给ChatGPT
  - [ ] 快速toggle，配置存在云端。登录时读到本地
  - [ ] 帮助
- 封装OpenAI功能
  - [x] 封装代理ChatGPT用SSE，文字呈现流式效果
  - [ ] 语音消息仿照微信
  - [x] 打字占位符
  - [ ] Emoji支持
  - [ ] 被邀请加入群聊，两个人对话，好像真实场景似的。其实是两个AI对话……
- 品牌元素
  - [ ] 名字，所有出现的地方
  - [ ] 图标
  - [ ] 启动图
- 用户体验改进
  - [x] 移动Web体验，滑动，选词，上屏
  - [x] 支持鼠标点击单词
  - [ ] 响应式设计，MVP需要适配PC Web和mobile Web的宽度以及操作。
  - [ ] 所有字体和样式整理，统一管理、规范使用。（google NotoSansSC字体被墙）
  - [ ] 动效
  - [ ] 支持在界面上按上下键（文本框无焦点时）
  - [ ] wordmatch里按下Tab键，可选lemma
  - [ ] 仿照输入法：左侧竖条，右侧浮动
- 运维工作
  - [x] 部署mysql,或用sqlite
  - [x] Redis
  - [x] 用户库。user_uuid为全局唯一ID，username在注册时要检查重复（区分大小写）
  - [x] 服务端日志
  - [ ] mysql。ChatGPT聊天记录
- 浏览器扩展 https://github.com/chibat/chrome-extension-typescript-starter
  - 单词本白名单，即可让用户把不认识的单词一键批量加入白名单，但需要先做两个工作：1按词频排序，2是让用户先选目标单词表。白名单的好处是后续阅读时（浏览器扩展）可以自动高亮生词。
  - [ ] 也可以是一个输入法