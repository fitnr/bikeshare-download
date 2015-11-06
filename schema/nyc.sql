CREATE TABLE IF NOT EXISTS `nyc_trips` (
    `duration` INTEGER NOT NULL,
    `startid` INTEGER NOT NULL,
    `starttime` DATETIME NOT NULL,
    `startname` VARCHAR(31) NOT NULL,
    `startlat` FLOAT NOT NULL,
    `startlon` FLOAT NOT NULL,
    `endid` INTEGER NOT NULL,
    `endtime` DATETIME NOT NULL,
    `endname` VARCHAR(33) NOT NULL,
    `endlat` FLOAT NOT NULL,
    `endlon` FLOAT NOT NULL,
    `bikeid` INTEGER NOT NULL,
    `usertype` VARCHAR(10) NOT NULL,
    `birthyear` INTEGER,
    `gender` INTEGER NOT NULL,
    KEY `sid` (`startid`),
    KEY `eid` (`endid`),
    KEY `time` (`starttime`, `duration`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `nyc_stations` (
    `id` INTEGER NOT NULL,
    `name` VARCHAR(31) NOT NULL,
    `lat` FLOAT,
    `lon` FLOAT,
    `borough` INTEGER,
    PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8;

