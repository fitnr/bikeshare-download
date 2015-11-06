# bikeshare data downloader
# Copyright (C) 2015 Neil Freeman <contact@fakeisthenewreal.org>
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS)
PASSFLAG = -p
PASS ?=

CURL = curl
CURLFLAGS = --silent

OGR = ogr2ogr

DATABASE = bikesharedata
DATA = data

comma = ,
empty =
space = $(empty) $(empty)

BOROUGHFILE = http://www.nyc.gov/html/dcp/download/bytes/nybbwi_15c.zip

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

include config/dc.ini

DC_FIELDS = @duration @starttime @endtime \
	startname endname bikeid usertype

include config/chi.ini

CHI_FIELDS = tripid @starttime @endtime bikeid duration startid \
	startname endid endname usertype gender birthyear

.PHONY: all csv-% mysql-%

all:
	@echo available tasks: mysql-nyc mysql-dc csv-nyc csv-dc mysql-chicago csv-chicago

mysql-nyc: $(foreach x,$(NYC_TRIPS),mysql-load-nyc-$x)
csv-nyc: $(foreach x,$(NYC_TRIPS),$(DATA)/nyc/$x.csv)

mysql-dc: $(foreach x,$(DC_TRIPS),mysql-load-dc-$x)
csv-dc: $(foreach x,$(DC_TRIPS),$(DATA)/dc/$x.csv)

mysql-chicago: $(foreach x,$(CHI_TRIPS),mysql-load-chi-$x) mysql-stations-chicago
mysql-stations-chicago: $(foreach x,$(CHI_STATIONS),mysql-station-$x)
csv-chicago: $(foreach x,$(CHI_TRIPS),$(DATA)/chi/$x.csv) $(foreach x,$(CHI_STATIONS),$(DATA)/chi/$x-stn.csv)
zip-chicago: $(foreach x,$(CHI_TRIPS),$(DATA)/chi/$x.zip)

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
	endtime=$(call DATE_FORMAT,@endtime), \
	duration=$(call DURATION_FORMAT,@duration);"

mysql-load-chi-%: $(DATA)/chi/%.csv schema/chi.sql | mysql-create-chi
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "LOAD DATA LOCAL INFILE '$<' INTO TABLE chi_trips \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	($(subst $(space),$(comma) ,$(CHI_FIELDS))) \
	SET starttime=$(call DATE_FORMAT,@starttime), \
	endtime=$(call DATE_FORMAT,@endtime)"

mysql-station-%: $(DATA)/chi/%-stn.csv | mysql-create-chi
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "LOAD DATA LOCAL INFILE '$<' INTO TABLE chi_stations \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	(id, name, lat, lon, capacity, @null);"

# mysql create databases
mysql-create-%: schema/%.sql | mysql-create
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) < $<

mysql-create:
	$(MYSQL) $(MYSQLFLAGS) -e "CREATE DATABASE IF NOT EXISTS $(DATABASE)"

# unzip CSVs
$(DATA)/nyc/%.csv: $(DATA)/nyc/%.zip ; unzip -p $< > $@
$(DATA)/dc/%.csv: $(DATA)/dc/%.zip ; unzip -p $< > $@

# chicago rules
$(DATA)/chi/2013-stn.csv: data/chi/2013.zip
	unzip -p $< Divvy_Stations_Trips_2013/Divvy_Stations_2013.csv > $@

$(DATA)/chi/2014-1-stn.csv: data/chi/2014-01.zip
	unzip -p $< Divvy_Stations_2014-Q1Q2.xlsx | node_modules/.bin/j -q - > $@

$(DATA)/chi/2014-2-stn.csv: data/chi/2014-07.zip
	unzip -p $< Divvy_Stations_Trips_2014_Q3Q4/Divvy_Stations_2014-Q3Q4.csv > $@

$(DATA)/chi/2015-1-stn.csv: data/chi/2015-01.zip
	unzip -p $< Divvy_Stations_2015.csv > $@

$(DATA)/chi/2013.csv: data/chi/2013.zip
	unzip -p $< Divvy_Stations_Trips_2013/Divvy_Trips_2013.csv > $@

$(DATA)/chi/2014-01.csv: data/chi/2014-01.zip
	unzip -p $< Divvy_Trips_2014_Q1Q2.csv > $@

$(DATA)/chi/2014-Q3-07.csv $(DATA)/chi/2014-Q4.csv: $(DATA)/chi/%.csv: data/chi/2014-07.zip
	unzip -p $< Divvy_Stations_Trips_2014_Q3Q4/Divvy_Trips_$*.csv > $@	

$(DATA)/chi/2015-Q2.csv $(DATA)/chi/2015-Q1.csv: data/chi/%.csv: data/chi/2015-01.zip
	unzip -p $< Divvy_Trips_$*.csv > $@

# download zips

.PRECIOUS: $(DATA)/%.zip
.SECONDEXPANSION:
$(DATA)/%.zip: | $$(@D)
	$(CURL) $(CURLFLAGS) --location https://$($(subst /,_,$*)) -o $@

$(DATA) data/nyc data/dc data/chi geo: ; mkdir -p $@

# geo stuff
mysql-boroughs: geo/nycstations_borough.csv
	tail +2 $< | \
	sed -E 's/([0-9]+),([0-9]+)/UPDATE nyc_stations SET borough=\2 WHERE id=\1;/' | \
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE)

geo/nycstations_borough.csv: geo/nycstations.csv geo/nybbwi.shp
	$(OGR) -f CSV $@ $< -overwrite -dialect sqlite \
	-sql "SELECT stn.id id, BoroCode borough \
	FROM $(basename $(<F)) stn, '$(filter %nybbwi.shp,$^)'.nybbwi boro \
	WHERE ST_Contains((boro.Geometry), MakePoint(CAST(stn.lon as REAL), CAST(stn.lat AS REAL), 4326))"

geo/nycstations.csv: | geo
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "SELECT * FROM nyc_stations" | \
	sed "s/'/\'/;s/	/\",\"/g;s/^/\"/;s/$$/\"/;s/\n//g" > $@

geo/nybbwi.shp: geo/nybbwi_15c.zip
	$(OGR) $@ /vsizip/$</nybbwi_15c/nybbwi.shp -s_srs EPSG:2263 -t_srs EPSG:4326 -select BoroName,BoroCode

geo/nybbwi_15c.zip: | geo
	$(CURL) $(CURLFLAGS) $(BOROUGHFILE) -o $@

.PHONY: install clean-%
clean-nyc clean-chi clean-dc: clean-%:
	$(MYSQL) $(MYSQLFLAGS) -e "DROP TABLE IF EXISTS $*_trips; DROP TABLE IF EXISTS $*_stations;"

install: ; npm install
