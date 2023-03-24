# 部署说明

## 新增包的方法可以选择不直接修改pubspec.yaml，使用以下命令

`dart pub add url_launcher` 之后VSCode会自动执行`flutter packages get` 或 `flutter pub get`

`flutter pub run flutter_native_splash:create`

`flutter pub run flutter_launcher_icons:main`

## TODO

- 提速方案：
  - [x] 查询结果加缓存
  - 全用SSE+HTTP。SSE的缺点是客户端不能主动发请求。HTTP都可以改成204 "no content"，加快响应速度
  - 在线查询的话，一次返回整页20个单词详情，滚动时候首次加载也能忍受
  - [ ] 迁移到国内主机
  - [ ] wasm实现marisa-trie
- 用户注册
  - [ ] 规划PUBSUB type/channel，增加多用户支持。eventType="prod/dev/test" channel="hash(userId+salt)" 其中salt随机（更新回用户表）或者固定（用算法就能确定）
  - [ ] 微信登录
- 命令行增强
  - [x] 查找词根词缀
  - [ ] 翻译（ChatGPT）
  - [ ] 语音对话
  - [ ] 角色扮演
  - [ ] 聊天记录
- 封装OpenAI功能
  - [ ] 封装代理ChatGPT用SSE。
  - [ ] 其他类型消息，流式效果设计
  - [ ] 消息气泡改进：打字占位符；机器人发送任务卡片；被邀请加入群聊，两个人对话，好像真实场景似的。其实是两个AI对话……
- 品牌元素
  - [ ] 图标
  - [ ] 启动图
- 界面美化
  - [ ] 动效
- 运维工作。自动从github打包发布？没测试啊。
  - [x] 部署mysql,或用sqlite
  - [x] Redis
  - [ ] 用户库。userId为全局唯一ID，
  - [ ] 收集哪些数据做统计
  - [ ] ChatGPT聊天记录存本地还是云端
- 单词本
  - [ ] 导入
  - [ ] 导出
- 浏览器扩展 https://github.com/chibat/chrome-extension-typescript-starter
  - 单词本白名单，即可让用户把不认识的单词一键批量加入白名单，但需要先做两个工作：1按词频排序，2是让用户先选目标单词表。白名单的好处是后续阅读时（浏览器扩展）可以自动高亮生词。
  - [ ] 也可以是一个在线输入法。
- 界面交互改进
  - [ ] wordmatch里按下Tab键，可选lemma
  - [ ] 支持鼠标点击单词
  - [ ] 支持在界面上按上下键（文本框无焦点时）
  - [ ] 左侧竖条，右侧浮动