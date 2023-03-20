class MessageModel {
  final String userId;
  final int type;
  final dynamic dataList;

  MessageModel({required this.dataList, required this.type, required this.userId});
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      userId: json['userId'],
      type: json['type'],
      dataList: json['dataList'],
    );
  }
}
