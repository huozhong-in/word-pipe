# 部署说明

## 新增包的方法可以选择不直接修改pubspec.yaml，使用以下命令

`flutter pub add xxxx`

## 更新完毕图标后执行以下命令

`dart run flutter_launcher_icons`

## 本机开web-server，供内网的手机或模拟器测试mobile web

`flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`

## macOS build memo

build with macos 14.0
```
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf ~/Library/Caches/CocoaPods/
pod deintegrate
pod update
```

## TODO

- 品牌元素
  - [ ] [官网建设](https://framer.com/)，隐私协议，服务条款，开源软件列表，
- 产品功能
  - [x] 桌面版本能在线更新，能做到强制更新，但要么全部强制更新，要么都不强制更新。
  - [ ] 去掉邀请码机制，改为试用一周。订阅方式，macOS微信或支付宝扫码支付；iOS应用内付费，走苹果支付通道
  - [ ] 语音对话。[waveform](https://github.com/ryanheise/just_audio/issues/97)
  - [ ] 语音消息转文字后，帮助用户润色，然后再读出来。口语润色自带语法纠错。
  - [ ] shift+enter换行、enter发送，或者enter换行、cmd+enter发送
  - [ ] 词典用本地数据库。聊天记录本地缓存，减少网络查询。聊天记录还是需要放在云端，真人互聊、家庭号需要。收集信息是为了持续训练垂直领域模型
  - [ ] 优化token使用。使用LangChain或复制它的逻辑
  - [ ] 支持多个服务商的API。
  - [ ] 支持本地部署大模型
  - [ ] 什么时候开CoT? 通识教育中需要逻辑和推导的领域。 `Let's work this out in a step by step way to be sure we have the right answer.`
  - [ ] “直接告诉我答案”后，提示用户”打开英语输入助手，咱们做个造句练习吧！“，另外从生词本中每天找出一个单词来，进行练习。“不学习就不跟你聊！”
  - [ ] 更多prompt转制产品功能，到屏幕右侧。提供prompt template，在界面右侧提供一些常用的模板（最佳实践），用户可以选择，点击将文本框变成表单？
  - [ ] 多语言支持（界面翻译/多语种学习）
  - [ ] 单词本/生词本
    - [ ] 查过的词加入生词本。将ECDict的单词表放进来，让用户选。
    - [ ] 导入。开放平台从哪些地方体现？比如将百词斩中总也背不下来的词导入进来，不是替代其他成熟软件，而是AIGC特性做补充和发挥。利用ChatGPT背单词。提供界面方式+开放插件方式让用户导入生词本，标注每个生词的。怎么借助ChatGPT把生词本玩出花来？挖掘生词本潜力
    - [ ] 造句。将“熟练金字塔”画出来。
    - [ ] 出题。历届雅思真题
  - [ ] 家庭号
    - [ ] 家长给孩子开账号，相当于就是青少年模式。三人房间。一键切换到孩子账号，类似sudo
    - [ ] 个人资料页，年龄范围，可用于优化prompt。`You are a primary school teacher who can explain complex content to a level that a 7 or 8 year old child can understand. Please rewrite the following sentences to make them easier to understand:`
    - [ ] 改写扩写等，要结合界面和输入框做统一考虑。输入框随着行数增加而变高，最高10行。
  - [ ] 滚动和搜索。[ListView性能优化](https://github.com/LianjiaTech/keframe/blob/master/README-ZH.md)
  - [ ] iOS [访问开发环境API不使用https](https://stackoverflow.com/questions/31254725/transport-security-has-blocked-a-cleartext-http/32331282#32331282)
  - [ ] 帮助和反馈渠道。使用企业微信群和电子邮件。稍后用ChatGPT学习产品说明书。
  - [ ] 新消息来后，底部增加提示，点击跳转
  - [ ] Markdown支持
  - [ ] Emoji支持
  - [ ] 高亮机器人文字里的生词。出题，造句
  - [ ] 机器人发送卡片
  - [ ] 支持在界面上按上下键（文本框无焦点时）
  - [ ] wordmatch里按下Tab键，可选lemma
- 运维工作
  - [ ] 迁移到国内主机。备案。内容审核问题。
- 浏览器扩展
  - [ ] 单词本白名单，即可让用户把不认识的单词一键批量加入白名单，但需要先做两个工作：1按词频排序，2是让用户先选目标单词表。白名单的好处是后续阅读时（浏览器扩展）可以自动高亮生词。
  - [ ] 也可以是一个在线输入法，比如谷歌输入法