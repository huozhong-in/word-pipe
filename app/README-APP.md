# 部署说明

## 新增包的方法可以选择不直接修改pubspec.yaml，使用以下命令

`dart pub add url_launcher` + `flutter pub get`

或 `flutter pub add url_launcher`

`flutter pub run flutter_launcher_icons:main`

## 本机开web-server，供内网的手机或模拟器测试mobile web

`flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`

## macOS build memo
build with macos 12.0
```
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf ~/Library/Caches/CocoaPods/
pod deintegrate
pod update
```

## TODO


- 品牌元素
  - [ ] 名字图标
  - [ ] 图标和favicon
  - [ ] 启动图
  - [ ] 动效
- 产品功能
  - [x] 用户名+密码方式注册，暂不提供找回密码
  - [x] 登录页做宽度适配
  - [x] 聊天记录。人们翻看回溯是为什么，能否提供有特色的聊天回顾功能，总结精简、提醒、标注、收藏？再利用、成就感】
  - [x] 响应式设计，MVP需要适配PC Web和mobile Web的宽度以及操作。
  - [x] 发送快捷键。Windows上是Ctrl+Enter，最好有个帮助tips出来，将来做到能配置。
  - [x] 所有字体和样式整理，统一管理、规范使用。字体大小设置放在Settings里
  - [ ] free chat mode，用户输入OpenAI apikey后开通
    - [ ] 优化token使用。一个配置项：压缩prompt以便节省token，压缩就是精简掉5轮之前的对话，精简掉的部分先做一个summary，限制max_token为200字。可否合并为一个请求？
    - [ ] 什么时候开CoT?`Let's work this out in a step by step way to be sure we have the right answer.`
    - [ ] “直接告诉我答案”后，提示用户“要不要做造句练习？”
    - [ ] 没有apikey的，再开收费模式
  - [ ] 单词本/生词本
    - [ ] 查过的词加入生词本
    - [ ] 导入。提供界面方式+开放插件方式让用户导入生词本，标注每个生词的。怎么借助ChatGPT把生词本玩出花来？挖掘生词本潜力
    - [ ] 导出。文本、CSV、PDF和anki connect
    - [ ] 造句。
    - [ ] 出题。
  - [ ] 语音消息转文字后，帮助用户润色，然后再读出来。口语润色自带语法纠错。
  - [ ] 家庭号
    - [ ] 能自己生成邀请码，看到绑定情况，还可以做备注。少于10个就可以再生成10个。
    - [ ] 个人资料页，年龄范围，可用于优化prompt。`You are a primary school teacher who can explain complex content to a level that a 7 or 8 year old child can understand. Please rewrite the following sentences to make them easier to understand:`
    - [ ] 将邀请码功能和社交功能尝试结合，比如对自己邀请的人，可以进入对方的会话，相当于建立三人小群，或者随时拉人进自己的“房间”——跟Jasmine的私聊房间。家庭号
    - [ ] 改写扩写等，要结合界面和输入框做统一考虑
  - [ ] act as
    - [x] 翻译（ChatGPT），默认是英英或快捷键或左侧菜单？【大模型背后的理解、推理能力也至关重要】
    - [x] 当作字典用。查词时给出词根词缀c词源
    - 角色扮演。在界面上设计几个典型的角色，老师、考官、同学、单词老师？如果是不同的上下文，建议做成多个聊天对象，放在左侧
  - [ ] 语音对话。默认是对话还是翻译？发语音是对话，发文字是翻译
  - [ ] 滚动和搜索
  - [ ] 帮助和反馈渠道。使用企业微信群和电子邮件。稍后用ChatGPT学习产品说明书。
  - [ ] 新消息来后，底部增加提示，点击跳转
  - [ ] 语音消息仿照微信。长度比例，播放体验，默认ASR。可配置默认播放。
  - [ ] Emoji支持
  - [ ] 高亮机器人文字里的生词。出题，造句
  - [ ] 机器人发送卡片
  - [ ] 支持在界面上按上下键（文本框无焦点时）
  - [ ] wordmatch里按下Tab键，可选lemma
  - [ ] 仿照输入法：左侧竖条，右侧浮动
  - [ ] 被邀请加入群聊，两个人对话，好像真实场景似的。其实是两个AI对话。后台架构是支持IM方式的。
  - [ ] 桌面版本必须能在线更新
- 可配置的项目在左侧，可快速toggle，角色扮演等工具显示在右侧
  - [ ] ，配置存在云端。登录时读到本地
- 运维工作
  - [ ] 迁移到国内主机。备案。内容审核问题。
  - [ ] wasm实现marisa-trie
  - [ ] mysql。本地聊天记录和词典用sqlite
  - [ ] 服务端日志
- 浏览器扩展 https://github.com/chibat/chrome-extension-typescript-starter
  - 单词本白名单，即可让用户把不认识的单词一键批量加入白名单，但需要先做两个工作：1按词频排序，2是让用户先选目标单词表。白名单的好处是后续阅读时（浏览器扩展）可以自动高亮生词。
  - [ ] 也可以是一个输入法