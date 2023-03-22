# 部署说明

## 新增包的方法可以选择不直接修改pubspec.yaml，使用以下命令

`dart pub add url_launcher` 之后VSCode会自动执行`flutter packages get` 或 `flutter pub get`

`flutter pub run flutter_native_splash:create`

`flutter pub run flutter_launcher_icons:main`

## TODO
- 词典打包问题
  - 提速方案：
    - 使用websocket替代HTTP接口？有点费劲，上线到真实服务器再说
    -[x] SSE的缺点是客户端不能主动发请求，只能服务器端推。HTTP都可以改成204。规划一下PUBSUB's type/channel，增加多用户支持
  - 缓存方案：
    - 本地放一份数据？单词名称表和单词详情表。查词功能几乎都在本地完成，但查询功能是键值对的方式，只能做点查询。但前缀匹配没法在Web页面端做。
    - 把线上字典都在localstorage重建（需要精简单词范围）。用斜线命令行方式提供，。
    -[x] 在线查询的话，一次返回整页20个单词详情，滚动时候首次加载也能忍受（考虑使用缓存）
  - 封装代理ChatGPT用SSE。翻译功能交给ChatGPT。
- 命令行增强
  - 将字典下载到本地LocalStorage
- 封装OpenAI功能
  - 其他类型消息，流式效果设计
  - 消息气泡改进：打字占位符；机器人发送任务卡片；被邀请加入群聊，两个人对话，好像真实场景似的。其实是两个AI对话……
- 品牌元素
  - 图标
  - 启动图
- 界面美化
  - 动效
- 用户注册登录
  -  微信登录
- 运维工作。自动从github打包发布？没测试啊。
  - flask业务数据库，已经部署了mysql，还要一份Redis
  - 用户库
  - 统计数据？
  - 聊天记录
  - ChatGPT聊天记录
- 生词本
  - 导入
  - 导出
  - 白名单方式，即可让用户把不认识的单词一键批量加入白名单，但需要先做两个工作：1按词频排序，2是让用户先选目标单词表。白名单的好处是后续阅读时（浏览器扩展）可以自动高亮生词。
- 浏览器扩展 https://github.com/chibat/chrome-extension-typescript-starter
  - 也可以是一个在线输入法。
- 界面交互改进
  - wordmatch里按下Tab键，可选lemma
  - 支持鼠标点击单词
  - 支持在界面上按上下键（文本框无焦点时）
  - 左侧竖条，右侧浮动