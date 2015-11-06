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

include config/nyc.ini

NYC_FIELDS = duration @starttime @endtime startid startname \
	startlat startlon endid endname endlat endlon \
    bikeid usertype birthyear gender

NYCS = 2013-07 2013-08 2013-09 2013-10 2013-11 2013-12 \
	2014-01 2014-02 2014-03 2014-04 2014-05 2014-06 2014-07 2014-08 2014-09 2014-10 2014-11 2014-12 2015-01 \
	2015-02 2015-03 2015-04 2015-05 2015-06 2015-07 2015-08


.PHONY: mysql-%

mysql-nyc: $(foreach x,$(NYCS),mysql-load-nyc-$x)
csv-nyc: $(foreach x,$(NYCS),$(DATA)/nyc/$x.csv)

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

	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	($(subst $(space),$(comma) ,$(NYC_FIELDS))) SET starttime=$(CASE_TIME);"

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


$(DATA) data/nyc: ; mkdir -p $@
