# 部署说明

## 新增包的方法可以选择不直接修改pubspec.yaml，使用以下命令

`dart pub add url_launcher`

`flutter pub get`

`flutter pub run flutter_native_splash:create`

`flutter pub run flutter_launcher_icons:main`

## TODO
- 正则表达式换掉
- 命令行增强
- 封装OpenAI功能
  - 其他类型消息
- 图标
- 启动图
- 界面美化
  - 动效
- 用户注册登录
  -  微信登录
- SSE通道的多用户支持
- 云端存储
  - flask后台数据库
  - 词典打包问题，需要测试和优化。尽早测试，影响体验
- 生词本
  - 导入
  - 导出
- 浏览器控件