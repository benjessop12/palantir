## Palantir Gem

### Quick introduction

Stock Analyzer. The bot scrapes stock data and analyses shill assertions to make informed predictions of the stock market using various indicator analysis methods.

Palantir currently utilizes the following indicator analysis methods:
  - Moving Average
  - Relative Strength Index

#### Configuration

The bot can be run with configured tickers to look at, analyzing frequently mentioned tickers or a mix of both.

To include tickers to be looked at, either pass the following environment variable against the base run task each time you want to run the bot:

`TICKERS=your,choice,of,ticker,codes` 

Or run the following for a sample file and replace the tickers in the file for subsequent runs:

`bundle exec palantir rake palantir:setup`

Please note, if a ticker config yaml file is present at run time, all stock tickers will be included in the run analysis.


#### Running

To build the docker images: `./bin/docker-build`

Once successfully built, `docker-compose up -d`
