MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS)
PASSFLAG = -p
PASS ?=

CURL = curl
CURLFLAGS = --silent

DATABASE = bikesharedata
DATA = data

comma = ,
empty =
space = $(empty) $(empty)

DATE_FORMAT = CASE WHEN POSITION('/' IN $1) \
	THEN STR_TO_DATE($1, '%m/%e/%Y %T') \
	ELSE $1 END

DURATION_FORMAT = CASE WHEN LOCATE('h', $1) \
	THEN TIME_TO_SEC(STR_TO_DATE($1, '%kh %im %Ss')) \
	ELSE $1/1000 END

include config/nyc.ini

NYC_FIELDS = duration @starttime @endtime startid startname \
	startlat startlon endid endname endlat endlon \
    bikeid usertype birthyear gender

NYCS = 2013-07 2013-08 2013-09 2013-10 2013-11 2013-12 \
	2014-01 2014-02 2014-03 2014-04 2014-05 2014-06 2014-07 2014-08 2014-09 2014-10 2014-11 2014-12 2015-01 \
	2015-02 2015-03 2015-04 2015-05 2015-06 2015-07 2015-08

include config/dc.ini

DC_FIELDS = @duration @starttime @endtime \
	startname endname bikeid usertype

DCS = 2010-Q1 2010-Q2 2010-Q3 2010-Q4 \
	2011-Q1 2011-Q2 2011-Q3 2011-Q4 \
	2012-Q1 2012-Q2 2012-Q3 2012-Q4 \
	2013-Q1 2013-Q2 2013-Q3 2013-Q3 \
	2014-Q1 2014-Q2 2014-Q3 2014-Q4 \
	2015-Q1 2015-Q2

.PHONY: all csv-% mysql-%

all:
	@echo available tasks: mysql-nyc mysql-dc csv-nyc csv-dc

mysql-nyc: $(foreach x,$(NYCS),mysql-load-nyc-$x)
csv-nyc: $(foreach x,$(NYCS),$(DATA)/nyc/$x.csv)

mysql-dc: $(foreach x,$(DCS),mysql-load-dc-$x)
csv-dc: $(foreach x,$(DCS),$(DATA)/dc/$x.csv)

# load into mysql
# load up stations table with new stations
mysql-load-nyc-%: $(DATA)/nyc/%.csv schema/nyc.sql | mysql-create-nyc
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "LOAD DATA LOCAL INFILE '$<' INTO TABLE nyc_trips \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	($(subst $(space),$(comma) ,$(NYC_FIELDS))) \
	SET starttime=$(call DATE_FORMAT,@starttime), \
	endtime=$(call DATE_FORMAT,@endtime);"

	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "INSERT INTO nyc_stations (id, name, lat, lon) \
	SELECT distinct startid, startname, startlat, startlon FROM nyc_trips t \
	LEFT JOIN nyc_stations s ON (t.startid=s.id) \
	WHERE starttime >= '$*-01' AND starttime < ADDDATE('$*-01', INTERVAL 1 MONTH) \
	AND s.id IS NULL;"

mysql-load-dc-%: $(DATA)/dc/%.csv schema/dc.sql | mysql-create-dc
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "LOAD DATA LOCAL INFILE '$<' INTO TABLE dc_trips \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	($(subst $(space),$(comma) ,$(DC_FIELDS))) \
	SET starttime=$(call DATE_FORMAT,@starttime), \
	stoptime=$(call DATE_FORMAT,@endtime), \
	duration=$(call DURATION_FORMAT,@duration);"

# mysql create databases
mysql-create-%: schema/%.sql | mysql-create
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) < $<

mysql-create:
	$(MYSQL) $(MYSQLFLAGS) -e "CREATE DATABASE IF NOT EXISTS $(DATABASE)"

# unzip CSVs
$(DATA)/%.csv: $(DATA)/%.zip
	unzip -p $< > $@

# download zips

.PRECIOUS: $(DATA)/%.zip
.SECONDEXPANSION:
$(DATA)/%.zip: | $$(@D)
	$(CURL) $(CURLFLAGS) --location https://$($(subst /,_,$*)) -o $@


