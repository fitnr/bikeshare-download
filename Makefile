include config/nyc.ini

MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS)
PASSFLAG = -p
PASS ?=

DATABASE = bikesharedata
DATA = data

comma = ,
empty =
space = $(empty) $(empty)

CASE_TIME = CASE WHEN POSITION('/' IN @starttime) \
	THEN STR_TO_DATE(@starttime, '%m/%e/%Y %T') \
	ELSE @starttime END

.PHONY: mysql-%

mysql-nyc-%: $(DATA)/nyc/%.csv schema/nyc.sql | mysql-create-nyc
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "LOAD DATA LOCAL INFILE '$<' INTO TABLE nyctrips \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	($(subst $(space),$(comma) ,$(NYC_FIELDS))) SET starttime=$(CASE_TIME);"

mysql-create-nyc: schema/nyc.sql | mysql-create
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) < $<

mysql-create:
	$(MYSQL) $(MYSQLFLAGS) -e "CREATE DATABASE IF NOT EXISTS $(DATABASE)"

$(DATA)/nyc/%.csv: $(DATA)/nyc/%.zip
	unzip -p $< > $@

.PRECIOUS: $(DATA)/nyc/%.zip
.SECONDEXPANSION:
$(DATA)/nyc/%.zip: | $$(@D)
	curl --silent --location https://$(NYC_$*) -o $@

$(DATA) data/nyc: ; mkdir -p $@
