CREATE DATABASE `tester`;

USE `tester`;

CREATE TABLE `articles` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `siteId` bigint(20) NOT NULL,
  `categoryId` bigint(20) NOT NULL DEFAULT '0',
  `timestamp` datetime NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` longtext NOT NULL,
  `tags` varchar(512) DEFAULT NULL,
  `seoMetaDesc` varchar(512) DEFAULT NULL,
  `seoMetaKeywords` varchar(512) DEFAULT NULL,
  `seoTitle` varchar(512) DEFAULT NULL,
  `priority` smallint(6) NOT NULL DEFAULT '0',
  `isVisibleOnMain` tinyint(1) NOT NULL DEFAULT '0',
  `isVisible` tinyint(1) NOT NULL DEFAULT '1',
  `isDeleted` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `siteId` (`siteId`,`categoryId`,`isVisible`,`isDeleted`,`isVisibleOnMain`),
  KEY `tags` (`tags`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `articles` VALUES (
    1,
    100500,
    0,
    '2029-06-21 20:31:32',
    'title',
    '<p>blah-blah-blah</p>',
    'tags',
    NULL,
    NULL,
    NULL,
    1,
    1,
    1,
    0
);
