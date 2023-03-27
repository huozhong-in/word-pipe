import 'package:app/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/validator.dart';
import 'dart:developer';


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