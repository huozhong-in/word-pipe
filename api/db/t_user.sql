/*
 Navicat Premium Data Transfer

 Source Server         : wordpipe
 Source Server Type    : SQLite
 Source Server Version : 3035005 (3.35.5)
 Source Schema         : main

 Target Server Type    : SQLite
 Target Server Version : 3035005 (3.35.5)
 File Encoding         : 65001

 Date: 24/03/2023 22:21:04
*/

PRAGMA foreign_keys = false;

-- ----------------------------
-- Table structure for t_user
-- ----------------------------
DROP TABLE IF EXISTS "t_user";
CREATE TABLE "t_user" (
  "pk_user" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  "uuid" text(36) NOT NULL,
  "unionid" text DEFAULT '',
  "refresh_token" TEXT DEFAULT 0,
  "mobile" TEXT(20) DEFAULT '',
  "user_name" TEXT(50) NOT NULL ON CONFLICT FAIL,
  "password" TEXT(64),
  "email" TEXT(64),
  "is_email_verified" integer(1) NOT NULL DEFAULT 0,
  "avatar" TEXT,
  "last_ip" TEXT(15),
  "sex" integer(1) NOT NULL DEFAULT 0,
  "ctime" integer(10),
  "utime" integer(10),
  "is_ban" integer(1) NOT NULL DEFAULT 0,
  CONSTRAINT "iq_user_name" UNIQUE ("user_name" ASC) ON CONFLICT FAIL
);

-- ----------------------------
-- Auto increment value for t_user
-- ----------------------------
UPDATE "main"."sqlite_sequence" SET seq = 1 WHERE name = 't_user';

-- ----------------------------
-- Indexes structure for table t_user
-- ----------------------------
CREATE INDEX "main"."ix_uuid"
ON "t_user" (
  "uuid" ASC
);

PRAGMA foreign_keys = true;
