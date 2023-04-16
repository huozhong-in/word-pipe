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

 Date: 16/04/2023 11:38:57
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
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------
-- Records of t_chat_record
-- ----------------------------
BEGIN;
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (1, '02b1c3be-aac5-4867-9361-ca724b87764e', 'b811abd7-c0bb-4301-9664-574d0d8b11f8', 1681446295, '[{\"role\": \"user\", \"content\": \"不期而遇的美好，用英文怎么说？一个单词。\"}]', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (2, 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '02b1c3be-aac5-4867-9361-ca724b87764e', 1681446296, 'Serendipity.', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (3, '02b1c3be-aac5-4867-9361-ca724b87764e', 'b811abd7-c0bb-4301-9664-574d0d8b11f8', 1681469885, '[{\"role\": \"user\", \"content\": \"Artificial Intelligence\"}]', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (4, 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '02b1c3be-aac5-4867-9361-ca724b87764e', 1681469894, 'Artificial Intelligence (AI) refers to the ability of machines to perform tasks that typically require human intelligence, such as speech recognition, decision-making, problem-solving, and language translation. AI involves the development and application of algorithms and statistical models that allow machines to learn from data and improve their performance over time. AI is used in a wide variety of applications, including image and speech recognition, natural language processing, autonomous vehicles, predictive analytics, and robotics. While AI has the potential to revolutionize many industries, it also raises ethical concerns around issues such as job displacement, privacy, and bias.', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (5, '02b1c3be-aac5-4867-9361-ca724b87764e', 'b811abd7-c0bb-4301-9664-574d0d8b11f8', 1681557485, '[{\"role\": \"user\", \"content\": \"“哑巴英语”怎么翻译成英语？怎么地道的表示自己的英语能力停留在听和读的初级水平，在口语交流方面很欠缺？\"}]', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (6, 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '02b1c3be-aac5-4867-9361-ca724b87764e', 1681557491, '“哑巴英语”在英语中可以翻译为“broken English”或者“poor English”。要表达自己的英语能力停留在初级水平，在口语交流方面有欠缺，可以使用“my speaking skills in English are limited”或者“my English speaking ability is not very strong”。', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (7, '02b1c3be-aac5-4867-9361-ca724b87764e', 'b811abd7-c0bb-4301-9664-574d0d8b11f8', 1681560829, '[{\"role\": \"user\", \"content\": \"要想改进这一点，你有什么建议？\"}]', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (8, 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '02b1c3be-aac5-4867-9361-ca724b87764e', 1681560839, '作为AI语言模型，我会建议：\n\n1. 提供更详细和具体的需求和情况，这样可以更好地帮助解决问题，而不是泛泛而谈；\n2. 了解双方的需求和利益，充分沟通；\n3. 尝试找到更多的解决方案，不要局限于现有的思路；\n4. 在实践过程中不断优化和改进，不断反馈问题和解决方案。', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (9, '02b1c3be-aac5-4867-9361-ca724b87764e', 'b811abd7-c0bb-4301-9664-574d0d8b11f8', 1681612788, '[{\"role\": \"user\", \"content\": \"请问flutter中的scaffold 的appbar title 可以设置成两种字体大小吗？我想在App name旁边加一个小的beta字样\"}]', 1, 1, 1, 1);
INSERT INTO `t_chat_record` (`pk_chat_record`, `msgFrom`, `msgTo`, `msgCreateTime`, `msgContent`, `msgStatus`, `msgType`, `msgSource`, `msgDest`) VALUES (10, 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '02b1c3be-aac5-4867-9361-ca724b87764e', 1681612793, '可以使用RichText来实现这个效果。\n\n代码示例：\n\n```dart\nScaffold(\n  appBar: AppBar(\n    title: RichText(\n      text: TextSpan(\n        children: [\n          TextSpan(\n            text: \'App name\',\n            style: TextStyle(fontSize: 18),\n          ),\n          TextSpan(\n            text: \' beta\',\n            style: TextStyle(fontSize: 12),\n          ),\n        ],\n      ),\n    ),\n  ),\n  body: Center(\n    child: Text(\'Hello World\'),\n  ),\n);\n```\n\n在`RichText`中使用`TextSpan`来定义两个不同字体大小的文本块。第一个文本块是\"App name\"，使用18号字体；第二个文本块是\"beta\"，使用12号字体。这样可以使得AppBar标题显示出两种字体大小。', 1, 1, 1, 1);
COMMIT;

-- ----------------------------
-- Table structure for t_promo
-- ----------------------------
DROP TABLE IF EXISTS `t_promo`;
CREATE TABLE `t_promo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `promo` text NOT NULL,
  `bind_userid` text DEFAULT NULL,
  `gen_by` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `iq_promo` (`promo`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------
-- Records of t_promo
-- ----------------------------
BEGIN;
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (1, 'eAZftT', 'f968a76f-720b-4b1d-9194-e6816aefce00', '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (2, 'ZoWKuY', '2d617eed-0b88-4c5f-9b21-7aae68840ba3', '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (3, 'SWvaeU', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (4, 'EujOS3', 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (5, 'ZMapIY', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (6, 'HaTqXj', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (7, 'JquJu6', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (8, '7zW00w', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (9, 'VQpBzj', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (10, '5OZaWw', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (11, '88pBM2', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (12, '77H2hY', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (13, 'BWltX0', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (14, 'DlTvKD', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (15, '3nAZG3', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (16, 'RmQreH', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (17, 'NT5Y3O', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (18, 'uFX06F', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (19, 'yoqf4B', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (20, 'K71Axi', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (21, 'GtLUiY', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (22, 'zDkGli', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (23, 'oowtiY', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (24, 'v0Z1j0', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (25, 'XQEX4R', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (26, 'kaUBkZ', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (27, '4x3Uo5', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (28, 'E1tyVh', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (29, 'ucx2cG', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (30, '4PewH8', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (31, 'a5WBC2', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (32, 'VLkxOk', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (33, 'bXrQ1E', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (34, 'QnGBdi', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (35, 'zrPqGz', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (36, 'Rretsb', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (37, 'MCvGTH', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (38, 'qF3de2', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (39, '4z07ic', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (40, 'fYio1D', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (41, 'a71dCx', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (42, 'OTMypU', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (43, 'UmVZZn', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (44, 'Ux90qz', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (45, 'trADkb', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (46, 'Aqv45r', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (47, 'w3Wzzs', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (48, '6ZsyZg', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (49, 'f7Am8R', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (50, 'cO4vpm', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (51, 'I7whAw', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (52, '9XhLR8', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (53, 'OJymjc', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (54, 'Dx7vLz', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (55, '7i01mu', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (56, 'WjpK9A', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (57, 'KpJR3G', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (58, 'NDGWoJ', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (59, 'DtnQFJ', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (60, 'REu0fu', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (61, 'dr4an5', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (62, 'DLHeZu', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (63, '8XpQCW', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (64, 'sJqlDZ', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (65, 'HdfNv4', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (66, '8YUZDv', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (67, 'klhFiB', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (68, 'YTZIc0', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (69, 'QQc7gw', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (70, '1Ehtwl', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (71, 'IgQrL3', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (72, 'rJoJnu', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (73, 'qg7jPB', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (74, 'Kcqadv', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (75, 'L4g6L9', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (76, 'fpWnf7', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (77, 's6nVmh', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (78, 'EToVVM', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (79, 'VaEGRF', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (80, '4YT32h', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (81, '3lIF9W', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (82, 'onhtal', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (83, 'AfsZjy', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (84, '2sLfHt', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (85, 'Hf6VsJ', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (86, 'zukSAF', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (87, 'Y7z4c4', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (88, '3rOOn7', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (89, 'gE4rnm', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (90, 'BTRlsX', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (91, 'OGZbTE', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (92, 'vyW2xO', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (93, 'NEf2Lo', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (94, 'PRjeMe', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (95, 'SPdO9t', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (96, 'a34ev7', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (97, 'CTODyN', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (98, 'X10stq', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (99, 'Z7phPt', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
INSERT INTO `t_promo` (`id`, `promo`, `bind_userid`, `gen_by`) VALUES (100, 'tR7dKW', NULL, '02b1c3be-aac5-4867-9361-ca724b87764e');
COMMIT;

-- ----------------------------
-- Table structure for t_user
-- ----------------------------
DROP TABLE IF EXISTS `t_user`;
CREATE TABLE `t_user` (
  `pk_user` int(11) NOT NULL AUTO_INCREMENT,
  `uuid` varchar(36) NOT NULL,
  `unionid` varchar(255) DEFAULT '',
  `access_token` varchar(512) NOT NULL DEFAULT '',
  `access_token_expire_at` int(11) NOT NULL DEFAULT 0,
  `refresh_token` varchar(512) NOT NULL DEFAULT '',
  `refresh_token_expire_at` int(11) NOT NULL DEFAULT 0,
  `mobile` varchar(20) DEFAULT '',
  `user_name` varchar(50) NOT NULL,
  `password` varchar(64) DEFAULT NULL,
  `email` varchar(64) DEFAULT NULL,
  `is_email_verified` tinyint(1) NOT NULL DEFAULT 0,
  `avatar` varchar(255) DEFAULT NULL,
  `last_ip` varchar(15) DEFAULT NULL,
  `sex` tinyint(1) NOT NULL DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  `is_ban` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`pk_user`),
  UNIQUE KEY `iq_user_name` (`user_name`) USING BTREE,
  KEY `ix_uuid` (`uuid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------
-- Records of t_user
-- ----------------------------
BEGIN;
INSERT INTO `t_user` (`pk_user`, `uuid`, `unionid`, `access_token`, `access_token_expire_at`, `refresh_token`, `refresh_token_expire_at`, `mobile`, `user_name`, `password`, `email`, `is_email_verified`, `avatar`, `last_ip`, `sex`, `ctime`, `utime`, `is_ban`) VALUES (1, '02b1c3be-aac5-4867-9361-ca724b87764e', '', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJEaW8iLCJleHAiOjE2ODQyMDcyMjl9.Zl9HrgiILsJ8-FjWTqFBL2JXvlbzKkwp2b7DIuEqTiU', 1684207229, '', 0, '', 'Dio', 'e4ef79d93e6d9922a024b5cb3d263ff9db8b20860715bd84836b787d34bc9dd5', '', 0, NULL, '', 0, 1681444180, NULL, 0);
INSERT INTO `t_user` (`pk_user`, `uuid`, `unionid`, `access_token`, `access_token_expire_at`, `refresh_token`, `refresh_token_expire_at`, `mobile`, `user_name`, `password`, `email`, `is_email_verified`, `avatar`, `last_ip`, `sex`, `ctime`, `utime`, `is_ban`) VALUES (2, 'f968a76f-720b-4b1d-9194-e6816aefce00', '', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJCb25ueSIsImV4cCI6MTY4NDA4MDIyOX0.hi2mJsEPbpNLofkurdn7Yk7iRvdB8WSpcwhJj83ozT4', 1684080229, '', 0, '', 'Bonny', 'aa1110155da3552cf0be5502befd7dc264b7eff34c58fb9405ecda04eab59fda', '', 0, NULL, '', 0, 1681445785, NULL, 0);
INSERT INTO `t_user` (`pk_user`, `uuid`, `unionid`, `access_token`, `access_token_expire_at`, `refresh_token`, `refresh_token_expire_at`, `mobile`, `user_name`, `password`, `email`, `is_email_verified`, `avatar`, `last_ip`, `sex`, `ctime`, `utime`, `is_ban`) VALUES (3, 'b811abd7-c0bb-4301-9664-574d0d8b11f8', '', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJKYXJ2aXMiLCJleHAiOjE2ODQwMzg4ODd9.l0JcRCbycRARo9SXqyW45M74GgXJboyEHWwyG-iv3a8', 1684038887, '', 0, '', 'Jarvis', '646628d9ee5abb439cde8fefd57c9994d174172913aa1cea7bab5b2bd8e02411', '', 0, NULL, '', 0, 1681446887, NULL, 0);
INSERT INTO `t_user` (`pk_user`, `uuid`, `unionid`, `access_token`, `access_token_expire_at`, `refresh_token`, `refresh_token_expire_at`, `mobile`, `user_name`, `password`, `email`, `is_email_verified`, `avatar`, `last_ip`, `sex`, `ctime`, `utime`, `is_ban`) VALUES (4, '2d617eed-0b88-4c5f-9b21-7aae68840ba3', '', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJGYW5nIiwiZXhwIjoxNjg0MDc5NDEzfQ.sWFnLP8XBi8zLHUNI2aXNeRbrY8N4IZCnWiCcgl2fdU', 1684079413, '', 0, '', 'Fang', '02131ba77bf4b6ff5985adf7357b7b34b1c0e29ebb6875764b86650c601f53c4', '', 0, NULL, '', 0, 1681447466, NULL, 0);
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
