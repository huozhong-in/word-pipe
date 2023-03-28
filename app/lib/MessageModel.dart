class MessageModel {
  final String username;
  final int type;
  final dynamic dataList;

  MessageModel({required this.dataList, required this.type, required this.username});
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json['username'],
      type: json['type'],
      dataList: json['dataList'],
    );
  }
}
