/*
 Navicat Premium Data Transfer

 Source Server         : wordpipe-mariadb
 Source Server Type    : MariaDB
 Source Server Version : 101102 (10.11.2-MariaDB-1:10.11.2+maria~ubu2204)
 Source Host           : 127.0.0.1:3306
 Source Schema         : wordpipe

 Target Server Type    : MariaDB
 Target Server Version : 101102 (10.11.2-MariaDB-1:10.11.2+maria~ubu2204)
 File Encoding         : 65001

 Date: 11/04/2023 23:55:17
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_chat_record
-- ----------------------------
DROP TABLE IF EXISTS `t_chat_record`;
CREATE TABLE `t_chat_record` (
  `pk_chat_record` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `msgFrom` varchar(36) NOT NULL,
  `msgTo` varchar(36) NOT NULL,
  `msgCreateTime` int(10) unsigned NOT NULL DEFAULT 0,
  `msgContent` longtext NOT NULL,
  `msgStatus` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `msgType` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `msgSource` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `msgDest` tinyint(1) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`pk_chat_record`),
  KEY `idx_my_chat_record` (`pk_chat_record`,`msgFrom`,`msgTo`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=102 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;
