import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:wordpipe/validator.dart';
import 'package:wordpipe/responsive/sign_up.dart';
import 'package:wordpipe/custom_widgets.dart';

// ignore: must_be_immutable
class MobileSignIn extends StatelessWidget {
  MobileSignIn({super.key});
  final Controller c = Get.find();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameField = TextEditingController();
  final TextEditingController _passwordField = TextEditingController();
  RxBool _obscureText = true.obs;


  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Text('用户登录', style: TextStyle(color: Colors.white70, fontSize: 24)),
          centerTitle: true,
          backgroundColor: CustomColors.appBarColor2,
          automaticallyImplyLeading: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(50),
            ),
          ),
        ),
        resizeToAvoidBottomInset : true,
        body: Container(
          height: Get.height,
          width: Get.width,
          child: Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: WordPipeLogo(context),
                      )
                    ],
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          // padding: EdgeInsets.only(top: 1),
                          // width: MediaQuery.of(context).size.width / 1.3,
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
                                  color: CustomColors.inputTextFieldBorder,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10),),
                                borderSide: BorderSide(
                                  color: CustomColors.firebaseOrange,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors.firebaseAmber,
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
                          // width: MediaQuery.of(context).size.width / 1.3,
                          height: 70,
                          child: Obx(() {
                            return TextFormField(
                            style: const TextStyle(color: Colors.black87),
                            textAlignVertical: TextAlignVertical.bottom,
                            controller: _passwordField,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscureText.value,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              // hintText: "Password",
                              // hintStyle: TextStyle(
                              //   color: Colors.grey,
                              // ),
                              // errorText: _errorText.value,
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
                                  color: CustomColors.inputTextFieldBorder,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10),),
                                borderSide: BorderSide(
                                  color: CustomColors.firebaseOrange,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors.firebaseAmber,
                                  width: 1,
                                ),
                              ),
                              suffixIcon: 
                                IconButton(
                                  onPressed: (){
                                    _obscureText.value = !_obscureText.value;
                                  },
                                  icon: Icon(
                                    _obscureText.value ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                )
                            ),
                            validator: (value) => Validator.validatePassword(
                              password: value!,
                            ),
                          );
                          })
                          
                        ),
                        Container(
                          // width: MediaQuery.of(context).size.width / 1.3,
                          height: 45,
                          // alignment: Alignment.,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Get.offAll(() => SignUp());
                                },
                                child: Text("没有账号? 点此注册",
                                  style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold, color: Colors.green[900]),
                                ),
                              ),
                              // TextButton(
                              //   onPressed: () {
                              //     Get.to(ResetPassword());
                              //   },
                              //   child: Text("Forgot Password?",
                              //     style: TextStyle(fontSize: 12, color: CustomColors.linkTipText, decoration: TextDecoration.underline),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            child: Container(
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
                              // constraints: BoxConstraints(maxWidth: context.width / 1.3),
                              child: ElevatedButton(
                                onPressed: () async {
                                  _usernameFocusNode.unfocus();
                                  _passwordFocusNode.unfocus();
                                  if (_formKey.currentState!.validate()) {
                                    Map<String, dynamic> rsp = await c.signin(_usernameField.text, _passwordField.text);
                                    if (rsp['errcode'] == 0) {
                                        Get.offAll(() => ResponsiveLayout());
                                    }else{
                                      customSnackBar(title: "错误码:${rsp['errcode']}", content: '${rsp['errmsg']}');
                                    }
                                  }else{
                                    customSnackBar(title: "注意", content: '请检查用户名或密码的长度');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                ),
                                child: const Text("登录", style: TextStyle(color: Colors.white, fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ( ! GetPlatform.isMobile) const Divider(
                    height: 60,
                    thickness: 1,
                    indent: 30,
                    endIndent: 30,
                    color: Colors.grey,
                  ),
                  if ( ! GetPlatform.isMobile) Container(
                    width: MediaQuery.of(context).size.width / 1.4,
                    height: 45,
                    alignment: AlignmentDirectional.topCenter,
                    child: Text("Copyright 2023 wordpipe.in",
                      style: TextStyle(fontSize: 14, color: CustomColors.smallTipText),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}
