Bikeshare data downloader
=========================

This is a set of Make tasks for downloading bike share trip and station data and loading the data into MySQL. Currently New York, Chicago and Washington are included. Pull requests are welcome for other cities!

## Installation

Download or clone the repository, and open the folder in Terminal. If you only want work with New York or Washington data, you're done! To download Chicago data, run: `make install` (this requires [npm](https://docs.npmjs.com/getting-started/installing-node)).

## Use

To load New York data into a MySQL db, run:
````
make mysql-nyc USER=<myuser> PASS=<mypass>
````
(Replace <mypass> and <myuser> with your local MySQL username and password.)

Commands for other cities follow the same pattern:
* Chicago: `make mysql-chicago`
* Washington: `make mysql-dc`

This will download the Citi Bike data zips, extract them, and load them into a MySQL database named `bikesharedata`. You can change the name of the database with `DATABASE=<name>`.

To only get CSV files, run: `make csv-nyc` (or `csv-chicago` or `csv-dc`).

To load the data into a remote MySQL database, use the MYSQLFLAGS variable:
````
make mysql-nyc USER=<myuser> PASS=<mypass> MYSQLFLAGS="-H myhost.com -P 5432"
````

If something goes wrong, you can clean out the files for a city with `make clean-nyc USER=<myuser> PASS=<mypass>`.

## New data

New data files have to be manually added to the repository, pull requests are accepted. To add a new file, update the appropriate file in the `config` directory. Add a new key-value pair for the file, following the format (no https:// prefix):
```ini
nyc_2020-08 = s3.amazonaws.com/tripdata/2020-08-citibike-tripdata.zip
```
Then, add the 'nugget' from the key (`2015-08`) to the `TRIPS` list at the end of the `ini` file:
`NYC_TRIPS = .... 2020-08`.

## Adding boroughs to New York

If you have [GDAL](http://www.gdal.org) installed, you can add borough information to the `nyc_stations` table. Run:
```
make mysql-boroughs USER=<mysqluser> PASS=<mysqlpass>
```
