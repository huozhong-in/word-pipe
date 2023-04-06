import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageModel {
  final String username;
  final RxList<dynamic> dataList;
  final RxInt type; // 修改为RxInt类型
  final Key key;

  MessageModel({
    required this.username,
    required this.dataList,
    required int type, // 修改构造函数参数类型为int
    required this.key,
  }) : type = type.obs; // 在构造函数中将type转换为RxInt

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json['username'],
      type: json['type'],
      dataList: json['dataList'],
      key: UniqueKey(), // 自动分配一个UniqueKey
    );
  }
}
