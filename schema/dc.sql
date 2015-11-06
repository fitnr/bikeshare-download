CREATE TABLE IF NOT EXISTS `dc_trips` (
    `duration` INTEGER NOT NULL,
    `starttime` DATETIME NOT NULL,
    `startname` VARCHAR(31) NOT NULL,
    `endtime` DATETIME NOT NULL,
    `endname` VARCHAR(33) NOT NULL,
    `bikeid` VARCHAR(7) NOT NULL,
    `usertype` VARCHAR(10) NOT NULL
)  DEFAULT CHARSET=utf8;