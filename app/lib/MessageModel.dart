import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageModel {
  final String username;
  final String uuid;
  final RxList<dynamic> dataList;
  final RxInt type; // 修改为RxInt类型
  final int createTime;
  final Key key;

  MessageModel({
    required this.username,
    required this.uuid,
    required this.dataList,
    required int type, // 修改构造函数参数类型为int
    required this.createTime,
    required this.key,
  }) : type = type.obs; // 在构造函数中将type转换为RxInt

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json['username'] as String,
      uuid: json['uuid'] as String,
      type: json['type'] as int,
      dataList: RxList(json['dataList']),
      createTime: json['createTime'] as int,
      key: UniqueKey(), // 自动分配一个UniqueKey
    );
  }
}
