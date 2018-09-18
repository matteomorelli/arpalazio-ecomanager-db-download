# Ecomanager Database Downloader

This script is a wrapper built to make easy download station data from an ecomanager server based on postgreSQL.
It supports two output format:
Ecomanager format is a basic format that enable user to make any type of analisys he wants on station data, for further information on data type see EcomanagerWEB's documentation.
Infoaria format is a specific format used for data post processing as required by [project InfoAria](http://www.webinfoaria.sinanet.isprambiente.it)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

* Cygwin or Linux environment
* PostgreSQL client 

You must have a functional installation of postegreSQL client. Client download and installation instructions are available for all platform [here](https://www.postgresql.org/download/)

This is an example of client installation for the latest release of the client on Ubuntu system.
To install PostgreSQL on Ubuntu, use the apt-get (or other apt-driving) command:
```
apt-get install postgresql-10
```

### Installing

1. Check out a clone of this repo to a location of your choice, such as
   `git clone --depth=1 https://github.com/matteomorelli/arpalazio-ecomanager-db-download.git` or make a copy of `ecomanager_db_download.sh` and `LICENSE` files
2. Modify the following variable matching your test/production environment:
```
# --- START of User configuration parameter
# DB parameter
PSQLBIN=location of postgreSQL client binary file
DB_SERVER="ip or DNS name of the server"
DB_PORT="port number of database server, usually default is 5432"
USR="a valid database username"
DATABASE="a valid database password"
# Working directory
WORK="directory of script execution, leave $(pwd) if you do not know what this mean"
```
3. Ensure your script is executable (i.e. - run `chmod a+x ecomanager_db_download.sh`)
4. Run helper for usage: run `ecomanager_db_download.sh -h`

Usage example:
```
./ecomanager_db_download.sh -t e -s 2018/01/01 -e 2018/01/02 -o output_file.txt
```
On success, this will create a text file named `output_file.txt` with all the data downloaded from the database server
```
 netcd 	 statcd 	 paramcd 	 istanzacd 	    daydt     	  hourav  	 vflagcd 
     1 	      2 	       2 	         1 	 201801010100 	  158.358 	       9 
     1 	      2 	       3 	         1 	 201801010100 	  125.542 	       9 
     1 	      2 	       4 	         1 	 201801010100 	  32.8318 	       9 
     1 	      2 	       7 	         1 	 201801010100 	  6.45913 	       9 
     1 	      2 	      18 	         1 	 201801010100 	  22.1525 	       9 
     1 	      2 	      18 	         2 	 201801010100 	  8.92823 	       9 
     1 	      2 	      19 	         1 	 201801010100 	   89.537 	       9 
     1 	      2 	      25 	         1 	 201801010100 	        0 	       1 
```

## Deployment

See installing instruction

## Versioning

We use [SemVer](http://semver.org/) for versioning.

## Authors

* **Matteo Morelli** - *Initial work* - [matteomorelli](https://github.com/matteomorelli)

See also the list of [contributors](https://github.com/matteomorelli/arpalazio-ecomanager-db-download/contributors) who participated in this project.

* **Andrea Bolignano** - [andrea-bolignano](https://github.com/andrea-bolignano)

## License

This project is licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2 - see the [LICENSE](LICENSE) file for details

## Acknowledgments

* Roberto Sozzi

