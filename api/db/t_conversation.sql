/*
 Navicat Premium Data Transfer

 Source Server         : online-wordpipe.in
 Source Server Type    : MySQL
 Source Server Version : 101102 (10.11.2-MariaDB-1:10.11.2+maria~ubu2204-log)
 Source Host           : localhost:3306
 Source Schema         : wordpipe

 Target Server Type    : MySQL
 Target Server Version : 101102 (10.11.2-MariaDB-1:10.11.2+maria~ubu2204-log)
 File Encoding         : 65001

 Date: 07/05/2023 08:14:54
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_conversation
-- ----------------------------
DROP TABLE IF EXISTS `t_conversation`;
CREATE TABLE `t_conversation` (
  `pk_conversation` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(36) NOT NULL,
  `conversation_name` varchar(100) DEFAULT '',
  `is_deleted` int(1) NOT NULL DEFAULT 0,
  `conversation_create_time` int(11) NOT NULL,
  PRIMARY KEY (`pk_conversation`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;
