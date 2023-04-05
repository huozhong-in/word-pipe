import 'package:flutter/material.dart';

class MessageModel {
  final String username;
  final int type;
  final dynamic dataList;
  final Key key; // 新增key属性

  MessageModel({
    required this.dataList,
    required this.type,
    required this.username,
    required this.key, // 添加key的构造函数
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json['username'],
      type: json['type'],
      dataList: json['dataList'],
      key: UniqueKey(), // 自动分配一个UniqueKey
    );
  }

  MessageModel copyWith({dynamic dataList, int? type, String? username, Key? key}) {
    return MessageModel(
      dataList: dataList ?? this.dataList,
      type: type ?? this.type,
      username: username ?? this.username,
      key: key ?? this.key, // 将key属性也支持修改
    );
  }
}
