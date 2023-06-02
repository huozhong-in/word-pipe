import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:wordpipe/config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于WordPipe', style: TextStyle(color: Colors.white, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 59, 214, 157),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.offAll(() => ResponsiveLayout());
          },
        )
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          padding: EdgeInsets.fromLTRB(20, 20, 10, 10),
          child: Card(
              color: Color.fromARGB(155, 59, 214, 157),
              elevation: 0,
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      Text(
                        'WordPipe是一个借助人工智能技术帮助你学习英语的应用程序,帮助用户从学习单词开始了解AI和使用AI。\n\n'
                        // 'WordPipe is an app that uses artificial intelligence technology to help you learn English and helps users understand AI and use AI from learning words. \n\n'
                        'WordPipe应用先进的人工智能技术,通过互动练习和个性化学习体验帮助用户学习英语。我们旨在打造一个随着用户使用逐渐变得“聪明“的AI语言伙伴。\n\n'
                        // 'WordPipe applies advanced artificial intelligence technology to help users learn English through interactive practice and personalized learning experiences. We aim to create an AI language partner that gradually becomes "smarter" as users use it.\n\n'
                        'WordPipe团队由来自科技、教育和语言学领域的专家组成。我们致力于研发出最具创新性和个性化的语言学习解决方案。\n\n'
                        // 'The WordPipe team consists of experts from the fields of science and technology, education and linguistics. We are committed to developing the most innovative and personalized language learning solutions.\n\n'
                        'WordPipe相信人工智能技术不光能生成优质教育内容，结合创新的用户体验，一定能够帮助用户以最有效和愉悦的方式学会一门语言。我们的目标是让更多人能够利用数字化工具学习语言,拥抱多语言文化,成为社会进步的推动者。\n\n'
                        // 'WordPipe believes that artificial intelligence technology, combined with high-quality educational content and innovative user experience, can surely help users learn a language in the most effective and pleasant way. Our goal is to enable more people to learn languages using digital tools, embrace multilingual culture, and become drivers of social progress. \n\n'
                        '团队愿景是帮助用户“养成“自己的语言AI助手，进而更好的利用全人类知识和全球信息源，并构建能跨越代际的数字资产和文化传承。\n\n'
                        // 'The team\'s vision is to help users "develop" their own language AI assistant, and then make better use of all human knowledge and global information sources, and build digital assets and cultural heritage that can transcend generations. \n'
                        ,style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87
                        ),
                      ),
                      Divider(
                        height: 20,
                        thickness: 1,
                        indent: 30,
                        endIndent: 30,
                        color: Colors.grey,
                      ),
                      Text(
                        '团队正在寻找创业小伙伴，产品经理、交互设计、社区运营、AI专家等，欢迎来聊聊人工智能的未来。 \n'
                        // 'The team is looking for entrepreneurial partners, product managers, interaction designers, community operations, AI experts, welcome to talk about the future of artificial intelligence. '
                        ,style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl: "${HTTP_SERVER_HOST}/contact-us",
                        imageBuilder: (context, imageProvider) => Container(
                          width: 350,
                          height: 480,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          width: 350,
                          height: 480,
                          color: Colors.black12,
                          margin: const EdgeInsets.only(right: 8),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      )
                    ],
                  ),
                ),
              ),
          ),
        )
      )
    );
  }
}