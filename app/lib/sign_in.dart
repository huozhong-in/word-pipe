import 'package:app/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/validator.dart';
import 'package:app/user_profile.dart';
import 'package:app/sign_up.dart';
import 'dart:developer';


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
        backgroundColor: Colors.white,
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
                  // alignment: Alignment.center,
                  child: Text(
                    "Sign In",
                    style: textFontStyle.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
                  )
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 2),
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
                            Get.to(SignUp());
                          },
                          child: Text("Sign Up",
                            style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ResetPassword()));
                          },
                          child: Text("Forgot Password?",
                            style: TextStyle(fontSize: 12, color: CustomColors.linkTipText, decoration: TextDecoration.underline),
                          ),
                        ),
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
                        if (_formKey.currentState!.validate()) {
                          if (await c.signin(_usernameField.text, _passwordField.text)){
                            Get.offAll(UserProfile());
                          }else{
                            print("await c.signin...error");
                          }
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
class ResetPassword extends StatelessWidget {
  ResetPassword({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _emailField = TextEditingController();

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OKay"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Mail has send"),
      content: Text("Then click the link in mail."),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _emailFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          // backgroundColor: Color.fromARGB(255, 62, 182, 226),
          title: const Text("Reset Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset : false,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     colors: [
          //       Color.fromARGB(255, 148, 231, 225),
          //       Colors.deepOrange,
          //       Color.fromARGB(255, 62, 182, 226)
          //     ],
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //   ),
          // ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20,),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 50,
                      margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        // borderRadius: BorderRadius.circular(90),
                      ),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.deepPurple),
                        textAlignVertical: TextAlignVertical.bottom,
                        controller: _emailField,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: "Your email account...",
                          hintStyle: TextStyle(
                            fontFamily: 'Lexend Deca',
                            color: Colors.grey,
                          ),
                          fillColor: Colors.white,
                          // labelText: "Email",
                          // labelStyle: TextStyle(
                          //   fontFamily: 'Lexend Deca',
                          //   color: Colors.deepPurple,
                          // ),
                          prefixIcon: Icon(Icons.person_outline),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10),),
                            borderSide: BorderSide(
                              color: Colors.deepPurpleAccent,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurpleAccent,
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
                        validator: (value) => Validator.validateEmail(
                          email: value!,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height / 35,),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        // color: Colors.orangeAccent,
                        gradient: new LinearGradient(
                          // colors: [
                          //   Color.fromARGB(255, 148, 231, 225),
                          //   Color.fromARGB(255, 62, 182, 226)
                          // ],
                          colors: [
                            Colors.purple,
                            Colors.deepPurpleAccent,
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          _emailFocusNode.unfocus();
                          if (_formKey.currentState!.validate()){
                            // await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailField.text)
                            //   .then((value) {showAlertDialog(context);});
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Please check your email format'),
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Text("Send mail for reset password", style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    );
  }
}