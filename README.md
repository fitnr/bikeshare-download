Bikeshare data downloader
=========================

This is a set of Make tasks for downloading bike share trip and station data and loading the data into MySQL. Currently New York, Chicago and Washington are included. Pull requests are welcome for other cities!

## Installation

Download or clone the repository, and open the folder in Terminal. If you only want work with New York or Washington data, you're done! To download Chicago data, run: `make install` (this requires [npm](https://docs.npmjs.com/getting-started/installing-node)).

## Use

To download New York data, run:
````
make mysql-nyc USER=<mysqluser> PASS=<mysqlpass>
````

Replace <mysqlpass> and <mysqluser> with your local MySQL username and password.

This will download the Citi Bike data zips, extract them, and load them into a MySQL database named `bikesharedata`. You can change the name of the database with `DATABASE=<name>`.

To load the data into a remote MySQL database, use the MYSQLFLAGS variable:
````
make mysql-nyc USER=<mysqluser> PASS=<mysqlpass> MYSQLFLAGS="-H myhost.com -P 5432"
````

## Adding boroughs to New York

If you have [GDAL](http://www.gdal.org) installed, you can add borough information to the `nyc_stations` table. Run:
```
make mysql-nyc-boroughs USER=<mysqluser> PASS=<mysqlpass>
```
