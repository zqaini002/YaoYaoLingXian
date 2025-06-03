/*
 Navicat Premium Dump SQL

 Source Server         : 本地
 Source Server Type    : MySQL
 Source Server Version : 80042 (8.0.42)
 Source Host           : localhost:3306
 Source Schema         : dream_db

 Target Server Type    : MySQL
 Target Server Version : 80042 (8.0.42)
 File Encoding         : 65001

 Date: 03/06/2025 23:59:09
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for comment
-- ----------------------------
DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `post_id` bigint NOT NULL COMMENT '动态ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '评论内容',
  `parent_id` bigint NULL DEFAULT NULL COMMENT '父评论ID',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0-删除，1-正常',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_post_id`(`post_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '评论表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of comment
-- ----------------------------
INSERT INTO `comment` VALUES (1, 1, 3, '加油！学习语言需要坚持，我也在学英语，希望我们都能成功！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (2, 1, 4, '推荐你试试英语流利说这个App，对提高口语很有帮助。', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (3, 1, 5, '制定计划是个好习惯，祝你成功！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (4, 2, 3, '跑步最重要的是坚持，不要着急提高速度和距离，慢慢来！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (5, 2, 5, '我去年完成了半程马拉松，确实需要系统训练，加油！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (6, 3, 2, '笔记整理得很详细，对我帮助很大，谢谢分享！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (7, 3, 4, '我也在学Python，可以一起交流学习心得。', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (8, 3, 5, '编程确实很有趣，尤其是看到自己的代码能正常运行的时候。', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (9, 3, 2, '你学到哪个阶段了？我刚开始学习数据结构。', 7, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (10, 3, 4, '我正在学习Django框架，准备做个小项目。', 7, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (11, 4, 2, '构图很不错，继续加油！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (12, 4, 3, '第二张照片的光线处理得很好，有专业感。', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (13, 4, 5, '摄影需要不断实践，期待看到你更多的作品。', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (14, 4, 2, '请问你用的是什么相机？', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (15, 5, 2, '刀工确实是烹饪的基础，掌握好会事半功倍。', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (16, 5, 4, '学习烹饪太棒了，期待看到你的成果！', NULL, 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `comment` VALUES (17, 1, 1, '天天', 0, 1, '2025-05-24 01:56:40', '2025-05-24 01:56:40');

-- ----------------------------
-- Table structure for dream
-- ----------------------------
DROP TABLE IF EXISTS `dream`;
CREATE TABLE `dream`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '梦想标题',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '梦想描述',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分类',
  `priority` tinyint NULL DEFAULT 3 COMMENT '优先级：1-最高，5-最低',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0-放弃，1-进行中，2-已完成',
  `completion_rate` decimal(5, 2) NULL DEFAULT 0.00 COMMENT '完成率',
  `deadline` date NULL DEFAULT NULL COMMENT '截止日期',
  `expected_days` int NULL DEFAULT NULL COMMENT '预计所需天数',
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片URL',
  `is_public` tinyint NULL DEFAULT 0 COMMENT '是否公开：0-私密，1-公开',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_category`(`category` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 24 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '梦想目标表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of dream
-- ----------------------------
INSERT INTO `dream` VALUES (1, 2, '学习英语', '提高英语口语能力，能够流利地进行日常交流和商务沟通', '学习', 1, 1, 35.00, '2024-12-31', 365, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-20 13:54:35');
INSERT INTO `dream` VALUES (2, 2, '完成马拉松', '参加一次全程马拉松比赛并完赛', '健康', 2, 1, 29.00, '2024-06-30', 180, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:57:07');
INSERT INTO `dream` VALUES (3, 3, '学习编程', '掌握Python编程语言，能够独立开发小型应用', '学习', 1, 1, 50.00, '2024-08-31', 240, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:57:07');
INSERT INTO `dream` VALUES (4, 3, '环游欧洲', '游览欧洲五个国家的主要城市和景点', '旅行', 3, 1, 0.00, '2025-12-31', 30, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:57:08');
INSERT INTO `dream` VALUES (5, 4, '写一本小说', '完成一部8万字以上的科幻小说创作', '创作', 2, 1, 15.00, '2024-12-31', 300, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 0, '2025-05-16 15:42:50', '2025-05-25 01:57:08');
INSERT INTO `dream` VALUES (6, 4, '学习摄影', '系统学习摄影技巧，能够拍摄专业级风景和人像作品', '艺术', 2, 1, 40.00, '2024-10-31', 240, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:57:09');
INSERT INTO `dream` VALUES (7, 5, '创业开公司', '创办一家专注于健康饮食的初创公司', '职业', 1, 1, 10.00, '2025-06-30', 730, 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 0, '2025-05-16 15:42:50', '2025-05-25 01:57:09');
INSERT INTO `dream` VALUES (8, 5, '学习烹饪', '学习中餐、西餐和日料的基本烹饪技巧', '生活技能', 3, 1, 30.00, '2024-05-31', 180, 'https://images.unsplash.com/photo-1556910103-1c02745aae4d', 1, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `dream` VALUES (23, 1, 'jy', '', '学习', 3, 1, 0.00, '2025-06-29', 30, 'http://10.0.2.2:8080/api/files/common/20250530/0b67077a-897a-40af-b928-6d6f0ee3e96f.jpg', 1, '2025-05-30 01:27:12', '2025-05-30 01:27:12');

-- ----------------------------
-- Table structure for dream_resource
-- ----------------------------
DROP TABLE IF EXISTS `dream_resource`;
CREATE TABLE `dream_resource`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dream_id` bigint NOT NULL COMMENT '梦想ID',
  `resource_id` bigint NOT NULL COMMENT '资源ID',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_dream_resource`(`dream_id` ASC, `resource_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '梦想资源关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of dream_resource
-- ----------------------------
INSERT INTO `dream_resource` VALUES (1, 1, 1, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (2, 1, 2, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (3, 2, 3, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (4, 2, 4, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (5, 3, 5, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (6, 3, 6, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (7, 4, 7, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (8, 4, 8, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (9, 5, 9, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (10, 5, 10, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (11, 6, 11, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (12, 6, 12, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (13, 7, 13, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (14, 7, 14, '2025-05-16 15:42:50');
INSERT INTO `dream_resource` VALUES (15, 8, 15, '2025-05-16 15:42:50');

-- ----------------------------
-- Table structure for dream_tag
-- ----------------------------
DROP TABLE IF EXISTS `dream_tag`;
CREATE TABLE `dream_tag`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dream_id` bigint NOT NULL COMMENT '梦想ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_dream_tag`(`dream_id` ASC, `tag_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '梦想标签关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of dream_tag
-- ----------------------------
INSERT INTO `dream_tag` VALUES (1, 1, 8, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (2, 1, 1, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (3, 2, 7, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (4, 2, 2, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (5, 3, 9, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (6, 3, 1, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (7, 4, 4, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (8, 5, 11, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (9, 5, 6, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (10, 6, 13, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (11, 6, 6, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (12, 7, 14, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (13, 7, 3, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (14, 7, 5, '2025-05-16 15:42:50');
INSERT INTO `dream_tag` VALUES (15, 8, 2, '2025-05-16 15:42:50');

-- ----------------------------
-- Table structure for flyway_schema_history
-- ----------------------------
DROP TABLE IF EXISTS `flyway_schema_history`;
CREATE TABLE `flyway_schema_history`  (
  `installed_rank` int NOT NULL,
  `version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `script` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `checksum` int NULL DEFAULT NULL,
  `installed_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `installed_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `execution_time` int NOT NULL,
  `success` tinyint(1) NOT NULL,
  PRIMARY KEY (`installed_rank`) USING BTREE,
  INDEX `flyway_schema_history_s_idx`(`success` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of flyway_schema_history
-- ----------------------------
INSERT INTO `flyway_schema_history` VALUES (1, '0', '<< Flyway Baseline >>', 'BASELINE', '<< Flyway Baseline >>', NULL, 'root', '2025-05-16 18:52:00', 0, 1);

-- ----------------------------
-- Table structure for follow
-- ----------------------------
DROP TABLE IF EXISTS `follow`;
CREATE TABLE `follow`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `follower_id` bigint NOT NULL COMMENT '关注者ID',
  `following_id` bigint NOT NULL COMMENT '被关注者ID',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_follower_following`(`follower_id` ASC, `following_id` ASC) USING BTREE,
  INDEX `idx_follower_id`(`follower_id` ASC) USING BTREE,
  INDEX `idx_following_id`(`following_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '关注表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of follow
-- ----------------------------
INSERT INTO `follow` VALUES (1, 2, 3, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (2, 2, 4, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (3, 2, 5, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (4, 3, 2, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (5, 3, 4, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (6, 3, 5, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (7, 4, 2, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (8, 4, 3, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (9, 4, 5, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (10, 5, 2, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (11, 5, 3, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (12, 5, 4, '2025-05-16 15:42:50');
INSERT INTO `follow` VALUES (13, 1, 4, '2025-05-25 02:36:17');

-- ----------------------------
-- Table structure for like
-- ----------------------------
DROP TABLE IF EXISTS `like`;
CREATE TABLE `like`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `post_id` bigint NULL DEFAULT NULL COMMENT '动态ID',
  `comment_id` bigint NULL DEFAULT NULL COMMENT '评论ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_post_user`(`post_id` ASC, `user_id` ASC) USING BTREE,
  UNIQUE INDEX `idx_comment_user`(`comment_id` ASC, `user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 32 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '点赞表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of like
-- ----------------------------
INSERT INTO `like` VALUES (1, 1, NULL, 3, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (2, 1, NULL, 4, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (3, 1, NULL, 5, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (4, NULL, 1, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (5, NULL, 2, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (6, NULL, 3, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (8, 2, NULL, 5, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (9, NULL, 4, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (10, NULL, 5, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (11, 3, NULL, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (12, 3, NULL, 4, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (13, 3, NULL, 5, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (14, NULL, 6, 3, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (15, NULL, 7, 3, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (16, NULL, 8, 3, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (17, 4, NULL, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (18, 4, NULL, 3, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (19, 4, NULL, 5, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (20, NULL, 11, 4, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (21, NULL, 12, 4, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (22, NULL, 13, 4, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (23, 5, NULL, 2, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (24, 5, NULL, 4, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (25, NULL, 15, 5, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (26, NULL, 16, 5, '2025-05-16 15:42:50');
INSERT INTO `like` VALUES (31, 1, NULL, 1, '2025-05-27 19:03:16');

-- ----------------------------
-- Table structure for post
-- ----------------------------
DROP TABLE IF EXISTS `post`;
CREATE TABLE `post`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `dream_id` bigint NULL DEFAULT NULL COMMENT '关联的梦想ID',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '内容',
  `images` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '图片URL，多个用逗号分隔',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0-删除，1-正常',
  `view_count` int NULL DEFAULT 0 COMMENT '浏览次数',
  `like_count` int NULL DEFAULT 0 COMMENT '点赞次数',
  `comment_count` int NULL DEFAULT 0 COMMENT '评论次数',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_dream_id`(`dream_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '社区动态表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of post
-- ----------------------------
INSERT INTO `post` VALUES (1, 2, 1, '开始我的英语学习之旅', '今天正式开始我的英语学习计划，希望一年后能够流利地用英语交流。我制定了详细的学习计划，包括单词背诵、听力训练和口语练习。加油！', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, 78, 16, 4, '2025-05-16 15:42:50', '2025-05-27 19:03:16');
INSERT INTO `post` VALUES (2, 2, 2, '马拉松训练第一周', '这周开始了马拉松训练，虽然只是每次跑5公里，但已经让我感到有些吃力。不过，坚持就是胜利，我相信通过系统训练，一定能在明年完成全程马拉松！', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, 43, 9, 2, '2025-05-16 15:42:50', '2025-05-25 02:02:09');
INSERT INTO `post` VALUES (3, 3, 3, 'Python学习笔记分享', '学习Python已经两个月了，今天分享一些我的学习笔记和心得。编程真的很有趣，解决问题的过程让人很有成就感。附上我写的一些代码示例，希望对同样学习Python的朋友有帮助。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, 86, 20, 5, '2025-05-16 15:42:50', '2025-05-25 02:02:10');
INSERT INTO `post` VALUES (4, 4, 6, '我的摄影进阶之路', '开始系统学习摄影一个月了，从最基础的相机参数到构图技巧，每天都有新收获。分享几张我最近拍摄的作品，虽然还很业余，但已经能看到一些进步。期待未来能拍出更好的作品！', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, 55, 13, 4, '2025-05-16 15:42:50', '2025-05-25 02:02:10');
INSERT INTO `post` VALUES (5, 5, 8, '烹饪学习第一课：基础刀工', '今天上了烹饪课的第一堂课，学习了基础刀工。才知道原来切菜也是一门学问！分享一些学到的技巧：1. 握刀姿势要正确；2. 切菜要保持稳定的节奏；3. 不同食材需要不同的切法。明天将学习简单的炒菜技巧，很期待！', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, 37, 8, 2, '2025-05-16 15:42:50', '2025-05-25 02:02:11');
INSERT INTO `post` VALUES (7, 1, 23, 'fdaf', 'fdaf', 'http://10.0.2.2:8080/api/files/common/20250530/2499f792-595c-4127-848e-d7597367472e.jpg', 0, 1, 0, 0, '2025-05-30 01:27:34', '2025-05-30 01:41:58');
INSERT INTO `post` VALUES (8, 1, NULL, 'gfdf也一样ttttfdfffnijia', 'gfsg', NULL, 0, 7, 0, 0, '2025-05-30 01:42:12', '2025-05-30 02:15:51');

-- ----------------------------
-- Table structure for progress
-- ----------------------------
DROP TABLE IF EXISTS `progress`;
CREATE TABLE `progress`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dream_id` bigint NULL DEFAULT NULL COMMENT '梦想ID',
  `task_id` bigint NULL DEFAULT NULL COMMENT '任务ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '进度描述',
  `images` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '图片URL，多个用逗号分隔',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_dream_id`(`dream_id` ASC) USING BTREE,
  INDEX `idx_task_id`(`task_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '进度记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of progress
-- ----------------------------
INSERT INTO `progress` VALUES (1, 1, 1, 2, '完成了英语学习计划的制定，确定了每天学习2小时，重点提高听力和口语能力。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (2, 1, 2, 2, '今天背诵了20个新单词，并复习了昨天的单词，记忆效果不错。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (3, 1, 3, 2, '观看了《老友记》第一季第一集，大约能听懂60%的对话，需要继续努力。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (4, 1, 5, 2, '报名了线下英语培训班，每周六上课，为期3个月。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (5, 2, 6, 2, '制定了详细的马拉松训练计划，前期以提高基础耐力为主。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (6, 2, 7, 2, '今天完成了5公里的慢跑，用时35分钟，感觉还不错。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (7, 2, 10, 2, '购买了专业跑鞋和运动服装，为长期训练做准备。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (8, 3, 11, 3, '完成了Python基础语法的学习，能够理解和使用基本的数据类型、控制流和函数。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (9, 3, 12, 3, '完成了30个基础编程练习，对字符串、列表和字典的操作更加熟练。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (10, 3, 13, 3, '开始学习数据结构，理解了栈和队列的概念和实现方法。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (11, 5, 21, 4, '完成了小说的主题构思，确定为科幻题材，探讨人工智能与人类关系。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (12, 5, 22, 4, '创建了三个主要角色的详细设定，包括背景故事、性格特点和动机。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (13, 6, NULL, 4, '参加了摄影基础课程，学习了相机参数的基本设置和应用。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (14, 6, NULL, 4, '尝试了不同光线条件下的拍摄，理解了光线对摄影的重要性。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (15, 8, NULL, 5, '学习了基本的食材处理和刀工技巧，为烹饪打下基础。', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-16 15:42:50');
INSERT INTO `progress` VALUES (16, 1, 1, 2, 'xixi', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-18 02:26:47');
INSERT INTO `progress` VALUES (17, 1, 1, 2, 'wanc', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-18 02:27:20');
INSERT INTO `progress` VALUES (18, 1, 2, 2, 'xixi', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-18 02:31:12');
INSERT INTO `progress` VALUES (19, 1, 2, 2, 'haha', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', '2025-05-18 02:34:05');

-- ----------------------------
-- Table structure for resource
-- ----------------------------
DROP TABLE IF EXISTS `resource`;
CREATE TABLE `resource`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '资源标题',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '资源描述',
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '资源类型：课程、书籍、文章、视频等',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分类',
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '资源链接',
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片URL',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0-下架，1-上架',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_type`(`type` ASC) USING BTREE,
  INDEX `idx_category`(`category` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '资源表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of resource
-- ----------------------------
INSERT INTO `resource` VALUES (1, '英语流利说', '通过AI技术提高英语口语能力的App', '应用', '语言学习', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:03');
INSERT INTO `resource` VALUES (2, '可可英语', '提供英语听力、口语、阅读等全方位训练', '网站', '语言学习', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:05');
INSERT INTO `resource` VALUES (3, '跑步圣经', '马拉松训练指南，从零基础到完赛', '书籍', '运动健康', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:05');
INSERT INTO `resource` VALUES (4, '初级马拉松训练计划', '16周马拉松训练计划，适合初次参赛者', '课程', '运动健康', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:06');
INSERT INTO `resource` VALUES (5, 'Python零基础入门课程', '从零开始学习Python编程语言', '课程', '编程学习', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:06');
INSERT INTO `resource` VALUES (6, 'Python实战项目教程', '通过项目实践提高Python编程能力', '视频', '编程学习', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:07');
INSERT INTO `resource` VALUES (7, '欧洲自助游攻略', '详细介绍欧洲各国旅游信息和经验', '电子书', '旅行', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:08');
INSERT INTO `resource` VALUES (8, '欧洲文化艺术之旅', '探索欧洲各国的艺术、历史和文化', '视频', '旅行', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:08');
INSERT INTO `resource` VALUES (9, '小说创作指南', '从构思到成稿的小说写作全过程', '书籍', '写作', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:09');
INSERT INTO `resource` VALUES (10, '角色塑造技巧', '如何创造生动、立体的小说角色', '课程', '写作', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:10');
INSERT INTO `resource` VALUES (11, '摄影基础教程', '从入门到精通的摄影技巧指南', '课程', '摄影', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:10');
INSERT INTO `resource` VALUES (12, '风景摄影技巧', '如何拍摄出震撼人心的风景照片', '视频', '摄影', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:11');
INSERT INTO `resource` VALUES (13, '创业指南', '从0到1的创业全过程指导', '书籍', '创业', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:11');
INSERT INTO `resource` VALUES (14, '商业计划书编写', '如何撰写有说服力的商业计划书', '课程', '创业', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:12');
INSERT INTO `resource` VALUES (15, '中式烹饪入门', '中国传统菜系的基本烹饪技巧', '视频', '烹饪', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:13');

-- ----------------------------
-- Table structure for tag
-- ----------------------------
DROP TABLE IF EXISTS `tag`;
CREATE TABLE `tag`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '标签名称',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '标签分类',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '标签表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tag
-- ----------------------------
INSERT INTO `tag` VALUES (1, '学习', '个人发展', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (2, '健康', '生活方式', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (3, '职业', '个人发展', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (4, '旅行', '休闲娱乐', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (5, '财务', '个人发展', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (6, '艺术', '兴趣爱好', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (7, '运动', '健康', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (8, '语言', '学习', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (9, '编程', '学习', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (10, '阅读', '兴趣爱好', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (11, '写作', '兴趣爱好', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (12, '音乐', '兴趣爱好', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (13, '摄影', '兴趣爱好', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (14, '创业', '职业', '2025-05-16 15:42:50');
INSERT INTO `tag` VALUES (15, '人际关系', '社交', '2025-05-16 15:42:50');

-- ----------------------------
-- Table structure for task
-- ----------------------------
DROP TABLE IF EXISTS `task`;
CREATE TABLE `task`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dream_id` bigint NOT NULL COMMENT '关联的梦想ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '任务标题',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '任务描述',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0-待开始，1-进行中，2-已完成，3-已延期',
  `priority` tinyint NULL DEFAULT 3 COMMENT '优先级：1-最高，5-最低',
  `start_date` date NULL DEFAULT NULL COMMENT '开始日期',
  `due_date` date NULL DEFAULT NULL COMMENT '截止日期',
  `completed_at` datetime NULL DEFAULT NULL COMMENT '完成时间',
  `reminder_time` datetime NULL DEFAULT NULL COMMENT '提醒时间',
  `parent_task_id` bigint NULL DEFAULT NULL COMMENT '父任务ID',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_dream_id`(`dream_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_parent_task_id`(`parent_task_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 40 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '任务表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of task
-- ----------------------------
INSERT INTO `task` VALUES (1, 1, 2, '制定英语学习计划', '确定学习目标、资源和时间安排', 2, 1, '2023-10-01', '2023-10-07', '2025-05-18 00:00:00', NULL, NULL, '2025-05-16 15:42:50', '2025-05-18 05:56:01');
INSERT INTO `task` VALUES (2, 1, 2, '每天背诵20个英语单词', '使用单词卡片或App辅助记忆', 2, 2, '2023-10-08', '2024-12-31', '2025-05-18 00:00:00', '2023-10-08 08:00:00', NULL, '2025-05-16 15:42:50', '2025-05-18 05:56:18');
INSERT INTO `task` VALUES (3, 1, 2, '每周观看2部英语原版电影', '不看字幕，专注听力理解', 1, 3, '2023-10-08', '2024-12-31', NULL, '2023-10-14 20:00:00', NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (4, 1, 2, '参加线上英语角活动', '每周一次，与外国人交流', 0, 2, '2023-10-15', '2024-12-31', NULL, '2023-10-15 19:00:00', NULL, '2025-05-16 15:42:50', '2025-05-16 19:25:31');
INSERT INTO `task` VALUES (5, 1, 2, '报名英语培训班', '选择适合自己的英语培训机构并报名', 2, 2, '2023-10-10', '2023-10-20', '2023-10-18 00:00:00', NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (7, 2, 2, '每周慢跑3次，每次5公里', '建立基础耐力', 1, 2, '2023-11-08', '2024-01-31', NULL, '2023-11-08 18:00:00', NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (8, 2, 2, '每周进行一次长距离跑', '逐渐增加距离，适应长时间跑步', 1, 2, '2023-12-01', '2024-06-15', NULL, '2023-12-02 08:00:00', NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (9, 2, 2, '参加半程马拉松比赛', '获取比赛经验', 0, 2, '2024-03-01', '2024-03-31', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (10, 2, 2, '购买专业跑鞋和装备', '选择适合自己的专业跑步装备', 2, 3, '2023-11-05', '2023-11-15', '2023-11-12 00:00:00', NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (11, 3, 3, '学习Python基础语法', '通过在线课程或书籍学习基础知识', 2, 1, '2023-09-01', '2023-10-15', '2023-10-10 00:00:00', NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (12, 3, 3, '完成50个基础编程练习', '巩固基础知识', 2, 2, '2023-10-16', '2023-11-30', '2023-11-25 00:00:00', NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (13, 3, 3, '学习数据结构和算法', '掌握基本的数据结构和算法知识', 1, 2, '2023-12-01', '2024-01-31', NULL, '2023-12-01 20:00:00', NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (14, 3, 3, '开发一个简单的网页爬虫', '实践项目，爬取特定网站数据', 0, 2, '2024-02-01', '2024-02-28', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (15, 3, 3, '开发一个个人博客网站', '使用Django或Flask框架开发', 0, 1, '2024-03-01', '2024-06-30', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (16, 4, 3, '制定旅行计划', '确定旅行国家、城市和景点', 0, 1, '2025-01-01', '2025-02-28', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (17, 4, 3, '申请旅行签证', '准备材料并申请相关国家签证', 0, 1, '2025-03-01', '2025-04-30', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (18, 4, 3, '预订机票和住宿', '寻找优惠的机票和合适的住宿', 0, 2, '2025-05-01', '2025-06-30', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (19, 4, 3, '学习基本的旅行用语', '掌握目的地国家的基本用语', 0, 3, '2025-07-01', '2025-09-30', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (20, 4, 3, '购买旅行装备', '准备行李箱、转换插头等必要物品', 0, 3, '2025-10-01', '2025-11-30', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (21, 5, 4, '构思小说情节', '确定小说的主题、人物和基本情节', 2, 1, '2023-10-01', '2023-11-15', '2023-11-10 00:00:00', NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (22, 5, 4, '创建详细的人物设定', '设计主要角色的性格、背景和动机', 1, 2, '2023-11-16', '2023-12-31', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (23, 5, 4, '完成小说大纲', '规划小说的章节和发展脉络', 0, 1, '2024-01-01', '2024-01-31', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (24, 5, 4, '每周写作5000字', '保持稳定的写作进度', 0, 2, '2024-02-01', '2024-10-31', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (25, 5, 4, '寻找出版机会', '联系文学杂志或出版社', 0, 3, '2024-11-01', '2024-12-31', NULL, NULL, NULL, '2025-05-16 15:42:50', '2025-05-16 15:42:50');
INSERT INTO `task` VALUES (26, 1, 2, '英语口语练习与外教对话', '通过在线平台与外教进行30分钟英语口语练习，重点训练日常对话和商务表达', 2, 1, '2025-05-16', '2025-05-16', '2025-05-18 00:00:00', '2025-05-16 18:00:00', NULL, '2025-05-16 08:00:00', '2025-05-18 05:50:58');
INSERT INTO `task` VALUES (27, 2, 2, '完成10公里长跑训练', '配速控制在6分钟/公里，重点关注呼吸节奏和步频', 2, 2, '2025-05-16', '2025-05-16', '2025-05-16 00:00:00', '2025-05-16 17:30:00', NULL, '2025-05-16 08:30:00', '2025-05-16 19:25:25');
INSERT INTO `task` VALUES (28, 3, 3, 'Python数据分析练习', '使用Pandas库处理CSV数据集，完成数据清洗和基础分析', 1, 1, '2025-05-15', '2025-05-17', NULL, '2025-05-16 14:00:00', NULL, '2025-05-15 09:00:00', '2025-05-15 09:00:00');
INSERT INTO `task` VALUES (29, 8, 5, '学习法式煎蛋卷技巧', '观看教学视频并实践制作法式煎蛋卷，注意火候控制和翻面技巧', 0, 2, '2025-05-16', '2025-05-16', NULL, '2025-05-16 11:00:00', NULL, '2025-05-16 07:00:00', '2025-05-16 07:00:00');
INSERT INTO `task` VALUES (30, 6, 4, '室外人像摄影练习', '在自然光条件下拍摄人像，尝试不同光线角度和构图方式', 0, 2, '2025-05-16', '2025-05-16', NULL, '2025-05-16 16:00:00', NULL, '2025-05-16 08:15:00', '2025-05-16 08:15:00');
INSERT INTO `task` VALUES (31, 1, 2, '准备英语演讲稿', '为下周的英语演讲比赛准备3分钟的主题演讲稿，主题为\"科技与未来\"', 1, 1, '2025-05-14', '2025-05-18', NULL, '2025-05-17 20:00:00', NULL, '2025-05-14 10:00:00', '2025-05-18 02:50:02');
INSERT INTO `task` VALUES (32, 5, 4, '完成小说第一章修改', '根据编辑反馈修改小说第一章内容，重点完善人物对话和场景描写', 0, 2, '2025-05-13', '2025-05-19', NULL, '2025-05-17 22:00:00', NULL, '2025-05-13 11:30:00', '2025-05-13 11:30:00');
INSERT INTO `task` VALUES (33, 3, 3, '完成Web爬虫项目', '优化爬虫性能并添加数据存储功能，确保能稳定抓取目标网站内容', 1, 1, '2025-05-10', '2025-05-20', NULL, '2025-05-18 23:59:00', NULL, '2025-05-10 14:00:00', '2025-05-10 14:00:00');
INSERT INTO `task` VALUES (34, 7, 5, '制定创业商业计划书', '完成创业项目的商业计划书初稿，包括市场分析、运营模式和财务预测', 1, 1, '2025-05-01', '2025-05-30', NULL, '2025-05-25 18:00:00', NULL, '2025-05-01 09:00:00', '2025-05-01 09:00:00');
INSERT INTO `task` VALUES (35, 4, 3, '完成欧洲旅行预算规划', '制定详细的欧洲五国旅行预算，包括交通、住宿、餐饮和景点门票等费用', 1, 2, '2025-05-05', '2025-05-25', NULL, '2025-05-20 20:00:00', NULL, '2025-05-05 16:30:00', '2025-05-05 16:30:00');
INSERT INTO `task` VALUES (36, 1, 2, '复习英语单词50个', '使用Anki软件复习今天的50个新单词，重点是商务英语词汇', 0, 1, '2025-05-16', '2025-05-16', '2025-05-16 00:00:00', '2025-05-16 21:00:00', NULL, '2025-05-16 10:30:00', '2025-05-16 19:29:00');
INSERT INTO `task` VALUES (37, 2, 2, '进行力量训练', '完成30分钟的力量训练，包括俯卧撑、深蹲和平板支撑', 0, 2, '2025-05-16', '2025-05-16', '2025-05-16 00:00:00', '2025-05-16 19:00:00', NULL, '2025-05-16 09:45:00', '2025-05-16 19:28:56');
INSERT INTO `task` VALUES (38, 2, 2, '阅读马拉松训练书籍', '阅读《马拉松训练圣经》第3-5章，了解呼吸节奏控制方法', 0, 3, '2025-05-16', '2025-05-17', '2025-05-16 00:00:00', '2025-05-17 08:00:00', NULL, '2025-05-16 11:20:00', '2025-05-16 19:28:55');

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户名',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '头像URL',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '手机号',
  `gender` tinyint NULL DEFAULT 0 COMMENT '性别：0-未知，1-男，2-女',
  `birthday` date NULL DEFAULT NULL COMMENT '生日',
  `signature` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '个性签名',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-正常',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_username`(`username` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (1, 'admin', '$2a$10$JJtFy15D9xQm4Sg.Mx43xOPgl6Q4L15krdpRMJXMDww6pvEvEfpym', '管理员', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'admin@example.com', '13800000000', 1, '1990-01-01', '我是管理员', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:51');
INSERT INTO `user` VALUES (2, 'zhangsan', '$2a$10$JJtFy15D9xQm4Sg.Mx43xOPgl6Q4L15krdpRMJXMDww6pvEvEfpym', '张三', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'zhangsan@example.com', '13800000001', 1, '1992-05-20', '每天进步一点点', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:52');
INSERT INTO `user` VALUES (3, 'lisi', '$2a$10$JJtFy15D9xQm4Sg.Mx43xOPgl6Q4L15krdpRMJXMDww6pvEvEfpym', '李四', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'lisi@example.com', '13800000002', 2, '1995-08-15', '追求梦想的道路上', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:52');
INSERT INTO `user` VALUES (4, 'wangwu', '$2a$10$JJtFy15D9xQm4Sg.Mx43xOPgl6Q4L15krdpRMJXMDww6pvEvEfpym', '王五', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'wangwu@example.com', '13800000003', 1, '1998-12-05', '不忘初心，方得始终', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:53');
INSERT INTO `user` VALUES (5, 'zhaoliu', '$2a$10$JJtFy15D9xQm4Sg.Mx43xOPgl6Q4L15krdpRMJXMDww6pvEvEfpym', '赵六', 'http://10.0.2.2:8080/api/files/common/20250520/9e4162bc-a56b-4110-8de0-d9024780d40f.jpg', 'zhaoliu@example.com', '13800000004', 2, '1996-03-10', '努力奋斗，实现梦想', 1, '2025-05-16 15:42:50', '2025-05-25 01:58:54');

SET FOREIGN_KEY_CHECKS = 1;
