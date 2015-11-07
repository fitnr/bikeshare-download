CURL = curl
CURLFLAGS = --silent
LONDON = https://files.datapress.com/london/dataset/number-bicycle-hires/2015-10-13T11:53:02/tfl-daily-cycle-hires.xls

data/london/daily-trips.csv: data/london/tfl-daily-cycle-hires.xls
	node_modules/.bin/j -q --sheet Data $< | csvcut -c 1,2 > $@

data/london/tfl-daily-cycle-hires.xls: | data/london
	$(CURL) $(CURLFLAGS) -L $(LONDON) -o $@

data/london: ; mkdir -p $@
