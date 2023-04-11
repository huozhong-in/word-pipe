import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:app/config.dart';
import 'package:app/home.dart';
import 'package:app/controller.dart';
import 'package:app/validator.dart';
import 'package:app/user_profile.dart';
import 'package:app/sign_up.dart';
// import 'package:app/reset_password.dart';


// ignore: must_be_immutable
class SignIn extends StatelessWidget {
  SignIn({super.key});
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
        onTap: () {
          _usernameFocusNode.unfocus();
          _passwordFocusNode.unfocus();
        },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sign In'),
          centerTitle: true,
          backgroundColor: Colors.green.withOpacity(0.6),
          automaticallyImplyLeading: false,
          // leading: IconButton(
          //   icon: Icon(Icons.arrow_back),
          //   onPressed: () {
          //     Get.offAll(Home());
          //   },
          // )
        ),
        resizeToAvoidBottomInset : false,
        body: Column(
          // mainAxisSize: MainAxisSize.max,
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 30),
                  child: Text('Word Pipe',
                    style: TextStyle(
                      color: Colors.black54,
                      fontFamily: GoogleFonts.getFont('Comfortaa').fontFamily,
                      fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 35,),
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        // hintText: "Your User-Name",
                        // hintStyle: TextStyle(
                        //   color: Colors.grey,
                        // ),
                        labelText: "user name",
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
                        labelText: "password",
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
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 45,
                    // alignment: Alignment.,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.offAll(SignUp());
                          },
                          child: Text("Haven't an account? go to Sign Up",
                            style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Colors.green[900]),
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
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      // color: Colors.orangeAccent,
                      gradient: new LinearGradient(
                        // colors: [
                        //   Color.fromARGB(255, 148, 231, 225),
                        //   Color.fromARGB(255, 62, 182, 226)
                        // ],
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
                        if (_formKey.currentState!.validate() && await c.signin(_usernameField.text, _passwordField.text)) {
                            Get.offAll(Home());
                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Please check your username or password length'),
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text("Sign in", style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          //   const Divider(
          //     height: 60,
          //     thickness: 1,
          //     indent: 30,
          //     endIndent: 30,
          //     color: Colors.grey,
          //   ),
          //   Container(
          //     width: MediaQuery.of(context).size.width / 1.4,
          //     height: 45,
          //     alignment: AlignmentDirectional.topCenter,
          //     child: Text("Register or login as an account",
          //       style: textFontStyle.copyWith(fontSize: 14, color: CustomColors.smallTipText),
          //     ),
          //   ),
          //   Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       IconButton(
          //           onPressed: (){
                     
          //           },
          //           icon: Icon(Icons.email)),
          //       IconButton(onPressed: (){}, icon: FaIcon(FontAwesomeIcons.mobile), color: Colors.grey),
          //       IconButton(onPressed: (){}, icon: FaIcon(FontAwesomeIcons.apple), color: Colors.grey),
          //       IconButton(onPressed: (){}, icon: FaIcon(FontAwesomeIcons.google), color: Colors.grey),
          //     ],
          //   ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     IconButton(onPressed: (){}, icon: Icon(Icons.facebook), color: Colors.grey),
          //     IconButton(onPressed: (){}, icon: FaIcon(FontAwesomeIcons.twitter), color: Colors.grey),
          //     IconButton(onPressed: (){}, icon: FaIcon(FontAwesomeIcons.github), color: Colors.grey),
          //     IconButton(onPressed: (){}, icon: Icon(Icons.square), color: Colors.transparent),
          //   ],
          // ),
          ],
        ),
      )
    );
  }
}
