class Validator {
 
  static String? validateUserName({required String name}) {
    if (name.isEmpty) {
      return 'Name can\'t be empty';
    }
    if (name.contains(" ")){
      return 'Name can\'t contains SPACE';
    }
    // allow letter, number, 3~20 length
  if (name.length < 3 || name.length > 20)
    return 'please enter 3~20 letter or number';
  RegExp regex = RegExp(r"^[a-zA-Z0-9\w-]{3,20}$");
  if (!regex.hasMatch(name))
    return 'please enter 3~20 letter or number';
  else
    return null;
    // abandon words filter
  }

  static String? validateEmail({required String email}) {
    // RegExp emailRegExp = RegExp(
    //     r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    // if (email.isEmpty) {
    //   return 'Email can\'t be empty';
    // } else if (!emailRegExp.hasMatch(email)) {
    //   return 'Enter a correct email';
    // }
    // return null;
    String pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r"{0,253}[a-zA-Z0-9])?)*$";
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(email))
      return 'Enter a valid email address';
    else
      return null;
  }

  static String? validatePassword({required String password}) {
    if (password.isEmpty) {
      return 'Password can\'t be empty';
    } else if (password.length < 6) {
      return 'Enter a password with length at least 6';
    }
    RegExp regex = new RegExp(r"(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z]{6,16}$");
    if (!regex.hasMatch(password))
      return 'please enter 6~16 letter mix number';
    else
      return null;
  }
}
