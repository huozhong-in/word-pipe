import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/validator.dart';
import 'package:wordpipe/responsive/desktop_sign_in.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';


// ignore: must_be_immutable
class SignUp extends StatelessWidget {
  SignUp ({super.key});

  final Controller c = Get.find();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordFocusNode2 = FocusNode();
  final FocusNode _promoFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameField = TextEditingController();
  final TextEditingController _passwordField = TextEditingController();
  final TextEditingController _passwordField2 = TextEditingController();
  final TextEditingController _promoField = TextEditingController();
  RxBool _obscureText = true.obs;
  RxBool _obscureText2 = true.obs;


  @override
  Widget build(BuildContext context) {


      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Sign Up', style: TextStyle(color: Colors.white70, fontSize: 24)),
          centerTitle: true,
          backgroundColor: CustomColors.appBarColor2,
          automaticallyImplyLeading: false,
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
                    padding: EdgeInsets.only(top: 15),
                    child: RichText(
                          text: TextSpan(
                            text: 'Word Pipe',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.black54,
                              fontSize: 16,
                              fontFamily: GoogleFonts.getFont('Comfortaa').fontFamily,
                              fontWeight: FontWeight.w600),
                            children: <TextSpan>[
                              TextSpan(
                                text: '  alpha',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.black54,
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
                              // suffixIcon: 
                              //   IconButton(
                              //     onPressed: (){
                              //       _obscureText.value = !_obscureText.value;
                              //     },
                              //     icon: Icon(
                              //       _obscureText.value ? Icons.visibility : Icons.visibility_off,
                              //       color: Colors.grey,
                              //     ),
                              //   )
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
                        labelText: "password again",
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
                        // suffixIcon:
                        //   IconButton(
                        //     onPressed: (){
                        //       _obscureText2.value = !_obscureText2.value;
                        //     },
                        //     icon: Icon(
                        //       _obscureText2.value ? Icons.visibility : Icons.visibility_off,
                        //       color: Colors.grey,
                        //     ),
                        //   ),
                      ),
                      validator: (value) => _passwordField.text == _passwordField2.text ? null : "passwords don't match",
                    );
                    })
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 35,),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 70,
                    child: 
                      TextFormField(
                        style: const TextStyle(color: Colors.black87),
                        textAlignVertical: TextAlignVertical.bottom,
                        controller: _promoField,
                        focusNode: _promoFocusNode,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: "invite code",
                          labelStyle: TextStyle(
                            color: Colors.redAccent,
                          ),
                          prefixIcon: Icon(Icons.person_add_alt_1, color: Colors.redAccent,),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10),),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                      )
                    )
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 45,
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      child: Text("Already have an account?",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[900]),
                      ),
                      onPressed: () {
                        if ( GetPlatform.isDesktop)
                          Get.offAll(DesktopSignIn());
                        else
                          Get.offAll(MobileSignIn());
                      },
                    ),
                  ),
                  Container(
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
                          if (await c.signup_with_promo(_usernameField.text, _passwordField.text, _promoField.text)){
                            Get.offAll(ResponsiveLayout());
                          }else{
                            customSnackBar(title: "Error", content: "Please check your invite code or username already exist.");
                          }
                        }else{
                          customSnackBar(title: "Error", content: "Please check your username or password length.");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text("Sign up", style: TextStyle(color: Colors.white, fontSize: 14),
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
