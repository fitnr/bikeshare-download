CREATE TABLE IF NOT EXISTS `dctrips` (
    `duration` INTEGER NOT NULL,
    `starttime` DATETIME NOT NULL,
    `stoptime` DATETIME NOT NULL,
    `startname` VARCHAR(31) NOT NULL,
    `endname` VARCHAR(33) NOT NULL,
    `endtime` DATETIME NOT NULL,
    `bikeid` INTEGER NOT NULL,
    `usertype` VARCHAR(10) NOT NULL
);
