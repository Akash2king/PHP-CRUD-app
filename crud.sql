SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS `notes` (
  `noteID` int(11) NOT NULL AUTO_INCREMENT,
  `noteTitle` varchar(255) NOT NULL,
  `noteContent` varchar(255) NOT NULL,
  `noteDate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`noteID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user` (
  `username` varchar(255) NOT NULL,
  `userEmail` varchar(255) NOT NULL,
  `fullName` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  PRIMARY KEY (`username`),
  UNIQUE KEY `userEmail` (`userEmail`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `notes` (`noteID`, `noteTitle`, `noteContent`, `noteDate`) VALUES
(1, 'Cozy Coding', 'This is Some Cozy Coding Content\r\n', '2018-07-25 07:01:23'),
(3, 'A Post', 'Some Post', '2018-07-25 09:45:56');

INSERT IGNORE INTO `user` (`username`, `userEmail`, `fullName`, `password`) VALUES
('Cozy', 'cozy@dev.com', 'Cozy theDEV', '098f6bcd4621d373cade4e832627b4f6'),
('Cozy12', 'cozyswagez@outlook.com', 'Cosmas theDEV', '098f6bcd4621d373cade4e832627b4f6');
