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

 Date: 29/04/2023 13:35:43
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_conversation
-- ----------------------------
DROP TABLE IF EXISTS `t_conversation`;
CREATE TABLE `t_conversation` (
  `pk_conversation` int(11) NOT NULL,
  `uuid` varchar(36) NOT NULL,
  `conversation_name` varchar(255) DEFAULT NULL,
  `is_deleted` int(1) NOT NULL DEFAULT 0,
  `conversation_create_time` int(11) NOT NULL,
  PRIMARY KEY (`pk_conversation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;
