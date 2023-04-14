
import 'package:http/http.dart' as http;


Future<String> imageTypes(String url) async {
    var response = await http.head(Uri.parse(url));
    if (response.statusCode != 200){
      return "not exists";
    }
    response.headers.forEach((key, value) {
      print(key + " : " + value);
    });
    if(response.headers['content-type'] != null){
      if(response.headers['content-type']!.contains('jpeg')){
        return "jpeg";
      }else if(response.headers['content-type']!.contains('png')){
        return "png";
      }else if(response.headers['content-type']!.contains('svg')){
        return "svg";
      }   
    }
    return "not exists";
}

void main() async{
  if (await imageTypes("http://127.0.0.1/api/avatar/Jarvis")=="jpeg"){
    print('exists');
  }else{
    print('not exists');
  }
}
