import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/validator.dart';
import 'package:wordpipe/responsive/desktop_sign_in.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';
import 'package:wordpipe/custom_widgets.dart';

// ignore: must_be_immutable
class SignUp extends StatelessWidget {
  SignUp ({super.key});

  final Controller c = Get.find();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordFocusNode2 = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameField = TextEditingController();
  final TextEditingController _passwordField = TextEditingController();
  final TextEditingController _passwordField2 = TextEditingController();
  RxBool _obscureText = true.obs;
  RxBool _obscureText2 = true.obs;


  @override
  Widget build(BuildContext context) {


      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('用户注册', style: TextStyle(color: Colors.white70, fontSize: 24)),
          centerTitle: true,
          backgroundColor: CustomColors.appBarColor2,
          automaticallyImplyLeading: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(50),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: RichText(
                          text: TextSpan(
                            text: 'WordPipe',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.black54,
                              fontSize: 24,
                              fontFamily: 'SofadiOne'),
                            children: <TextSpan>[
                              TextSpan(
                                text: '  alpha',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.blue,
                                  fontSize: 10),
                              ),
                            ],
                          )
                        ),
                  ),
                  Container(
                    // padding: EdgeInsets.only(top: 1),
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      // textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.bottom,
                      controller: _usernameField,
                      focusNode: _usernameFocusNode,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        // hintText: "Your User-Name",
                        // hintStyle: TextStyle(
                        //   color: Colors.grey,
                        // ),
                        labelText: "用户名",
                        labelStyle: TextStyle(
                          color: Colors.black54,
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10),),
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10),),
                          borderSide: BorderSide(
                            color: Colors.redAccent,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.redAccent,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) => Validator.validateUserName(
                        name: value!,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 35,),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 70,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Obx(() {
                            return TextFormField(
                            style: const TextStyle(color: Colors.black87),
                            textAlignVertical: TextAlignVertical.bottom,
                            controller: _passwordField,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscureText.value,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: "密码",
                              labelStyle: TextStyle(
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.lock_outline),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10),),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10),),
                                borderSide: BorderSide(
                                  color: Colors.redAccent,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.redAccent,
                                  width: 1,
                                ),
                              ),
                            ),
                            validator: (value) => Validator.validatePassword(
                              password: value!,
                            ),
                          );
                          }),
                        ),
                      ],
                    )
                    
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 35,),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 70,
                    child: Obx(() {
                      return TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      textAlignVertical: TextAlignVertical.bottom,
                      controller: _passwordField2,
                      focusNode: _passwordFocusNode2,
                      obscureText: _obscureText2.value,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        // hintText: "Password",
                        // hintStyle: TextStyle(
                        //   color: Colors.grey,
                        // ),
                        labelText: "确认密码",
                        labelStyle: TextStyle(
                          color: Colors.black54,
                        ),
                        prefixIcon: Icon(Icons.lock_outline),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10),),
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10),),
                          borderSide: BorderSide(
                            color: Colors.redAccent,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.redAccent,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) => _passwordField.text == _passwordField2.text ? null : "两次输入的密码不一致",
                    );
                    })
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 45,
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      child: Text("已有账号? 点此登录",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[900]),
                      ),
                      onPressed: () {
                        if ( GetPlatform.isDesktop)
                          Get.offAll(() => DesktopSignIn());
                        else
                          Get.offAll(() => MobileSignIn());
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        width: MediaQuery.of(context).size.width / 1.3,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          // color: Colors.orangeAccent,
                          gradient: new LinearGradient(
                            colors: [
                              CustomColors.splashStart,
                              CustomColors.splashEnd,
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            _usernameFocusNode.unfocus();
                            _passwordFocusNode.unfocus();
                            _passwordFocusNode2.unfocus();
                            if (_formKey.currentState!.validate()) {
                              Map<String, dynamic> result = await c.signup(_usernameField.text, _passwordField.text);
                              if (result["errcode"] as int == 0){
                                Get.offAll(() => ResponsiveLayout());
                              }else{
                                customSnackBar(title: "Error", content: result["errmsg"] as String);
                              }
                            }else{
                              customSnackBar(title: "Error", content: "请检查用户名或密码的长度.");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: const Text("注册", style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
