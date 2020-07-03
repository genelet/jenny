
DROP TABLE IF EXISTS tabilet_login_a;
CREATE TABLE IF NOT EXISTS tabilet_login_a (
  a_id int unsigned not null auto_increment,
  email varchar(32) NOT NULL DEFAULT '',
  passwd varchar(40) NOT NULL DEFAULT '',
  firstname varchar(255) DEFAULT NULL,
  lastname varchar(255) DEFAULT NULL,
  status enum('Yes','No') DEFAULT 'Yes',
  created datetime DEFAULT NULL,
  PRIMARY KEY (a_id),
  UNIQUE KEY email (email(16))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS tabilet_login_a_tabilet_ip;
CREATE TABLE IF NOT EXISTS tabilet_login_a_tabilet_ip (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  ip int(10) unsigned NOT NULL,
  login VARCHAR(255) NOT NULL,
  updated timestamp,
  ret enum('fail','success') NOT NULL DEFAULT 'fail',
  PRIMARY KEY (id),
  KEY updated (updated),
  KEY ip (ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS poll_choice;
CREATE TABLE `poll_choice` (
  `choice_id` int(11) NOT NULL AUTO_INCREMENT,
  `poll_id` int(11) NOT NULL,
  `choice` varchar(255) NOT NULL,
  `votes` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`choice_id`),
  KEY `poll_id` (`poll_id`),
  CONSTRAINT `poll_choice_ibfk_1` FOREIGN KEY (`poll_id`) REFERENCES `poll_question` (`poll_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS poll_question;
CREATE TABLE `poll_question` (
  `poll_id` int(11) NOT NULL AUTO_INCREMENT,
  `question` varchar(255) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS Book3_csv;
CREATE TABLE `Book3_csv` (
  `tabilet_id` int(11) NOT NULL AUTO_INCREMENT,
  `RECALL_NUMBER_NUM` varchar(255) DEFAULT NULL,
  `YEAR` int(11) DEFAULT NULL,
  `MANUFACTURER_RECALL_NO_TXT` varchar(255) DEFAULT NULL,
  `CATEGORY_ETXT` varchar(255) DEFAULT NULL,
  `CATEGORY_FTXT` varchar(255) DEFAULT NULL,
  `MAKE_NAME_NM` varchar(255) DEFAULT NULL,
  `MODEL_NAME_NM` varchar(255) DEFAULT NULL,
  `UNIT_AFFECTED_NBR` double DEFAULT NULL,
  `SYSTEM_TYPE_ETXT` varchar(255) DEFAULT NULL,
  `SYSTEM_TYPE_FTXT` varchar(255) DEFAULT NULL,
  `NOTIFICATION_TYPE_ETXT` varchar(255) DEFAULT NULL,
  `NOTIFICATION_TYPE_FTXT` varchar(255) DEFAULT NULL,
  `COMMENT_ETXT` text,
  `COMMENT_FTXT` varchar(255) DEFAULT NULL,
  `RECALL_DATE_DTE` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`tabilet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP PROCEDURE IF EXISTS proc_jenny_a;
CREATE PROCEDURE proc_jenny_a (
IN i_login VARCHAR(255), IN i_passwd VARCHAR(255), IN i_ip INT unsigned,
OUT out_id INT unsigned, OUT out_login VARCHAR(255),
OUT out_firstname varchar(255), OUT out_lastname VARCHAR(255))
BEGIN
  DECLARE c1 INT;
  DECLARE c2 INT;
  SELECT COUNT(*) INTO c1 FROM tabilet_login_a_tabilet_ip WHERE ret='fail' AND ip=i_ip AND login=i_login AND (UNIX_TIMESTAMP(updated) >= (UNIX_TIMESTAMP(NOW())-3600));
  SELECT COUNT(*) INTO c2 FROM tabilet_login_a_tabilet_ip WHERE ret='fail' AND ip=i_ip AND (UNIX_TIMESTAMP(updated) >= (UNIX_TIMESTAMP(NOW())-24*3600));
  IF (c1<=5 AND c2<=20) THEN
    SELECT a_id, email, firstname, lastname INTO out_id, out_login, out_firstname, out_lastname
    FROM tabilet_login_a
    WHERE status IN ("Yes")
AND email =i_login
AND passwd=SHA1(concat(i_login, i_passwd));

    IF ISNULL(out_id) THEN
      INSERT INTO tabilet_login_a_tabilet_ip (ip,login,ret) VALUES (i_ip,i_login,'fail');
    ELSE
      DELETE FROM tabilet_login_a_tabilet_ip WHERE ret='fail' AND ip=i_ip AND (UNIX_TIMESTAMP(updated) >= (UNIX_TIMESTAMP(NOW())-24*3600));
      INSERT INTO tabilet_login_a_tabilet_ip (ip,login,ret) VALUES (i_ip,i_login,'success');
    END IF;
  ELSE
    SELECT '1030' INTO out_id;
  END IF;
END

