CREATE TABLE IF NOT EXISTS `nyctrips` (
    `duration` INTEGER NOT NULL,
    `starttime` DATETIME NOT NULL,
    `stoptime` DATETIME NOT NULL,
    `startid` INTEGER NOT NULL,
    `startname` VARCHAR(31) NOT NULL,
    `startlat` FLOAT NOT NULL,
    `startlng` FLOAT NOT NULL,
    `endid` INTEGER NOT NULL,
    `endname` VARCHAR(33) NOT NULL,
    `endlat` FLOAT NOT NULL,
    `endlng` FLOAT NOT NULL,
    `bikeid` INTEGER NOT NULL,
    `usertype` VARCHAR(10) NOT NULL,
    `birthyear` INTEGER,
    `gender` INTEGER NOT NULL
);
