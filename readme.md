## Palantir Gem

### Quick introduction

Stock Analyzer. The bot scrapes stock data and analyses shill assertions to make informed predictions of the stock market using various indicator analysis methods.

Palantir currently utilizes the following indicator analysis methods:
  - Moving Average
  - Relative Strength Index

#### Setup

To build the docker images: `./bin/docker-build`

Once successfully built, `docker-compose up -d`

#### Configuration

The bot can be run with configured tickers to look at, analyzing frequently mentioned tickers or a mix of both.

To include tickers to be looked at, either pass the following environment variable against the base run task each time you want to run the bot:

`TICKERS=your,choice,of,ticker,codes` 

Or run the following for a sample file and replace the tickers in the file for subsequent runs:

`bundle exec rake palantir:setup`

Please note, if a ticker config yaml file is present at run time, all stock tickers will be included in the run analysis.

This will also set up the postgres tables the run script requires for storing stock and assertion data.

#### Analytics

##### Moving Average

The moving average calculation creates a series of averages of different subsets of the full dataset and is a mitigator for short-term fluctuiations in the ticker price. There is a lag time with using longer lookback periods, which is considered a good thing for longevity. An analyst interested in short-term asseritons would look at a dataset which covers a small section of time in order to get the moving average with reduced lag. With more lag, you will see less short-term accuracy as the forecast will take longer to hit.

Simple moving average is the arithmetic mean of a given set of values and is as read: `sum_of_values / number_of_values`

The exponential moving average gives more weight to recent prices and is read:
```
smoothing_factor = [2 / (number_of_days + 1)]
exponential_moving_average_today = value_today * (smoothing_factor / (number_of_days + 1)) + exponential_moving_average_yesterday * [1 - (smoothing_factor / (number_of_days + 1))]
```
If it is the first time calculating the exponential moving average and yesterdays value is unavailable, substitute with the simple moving average.

##### Relative Strength Index

The relative strength index is the measure of magnitude of recent price changes and evaluates the overbought or oversold conditions. An RSI of over 70 indicates the security is overbought or overvalued and primed for a trend reversal or corrective pullback. An RSI of 30 or below indicates oversold or undervalued condition.

There are two stages to an RSI calculation:

First stage:
`100 - ( 100 / 1 + ( average_gain / average_loss))`

The average gain or loss used in the calculation is the average percentage gain or loss during a look-back period. The average loss shoild only ever be a positive value and the number of elements of the valculation should always be 14 or more.

Second stage:
```
100 - (
  100 / 1 + (
    (previous_average_gain * (number_of_elements - 1)) + current_gain
  ) - (
    (previous_average_loss * (number_of_elements - 1)) + current_loss
  )
)
```

The RSI will rise as the number and size of positive closes increase and alls the number and size of losses increase. Up periods are characterized by the close being higher than the previous close. Down periods are characterized by the close being lower than the previous periods. Down periods can only be a positive number.

#### Fun code stuff

There is a question of using Docker in a gem, to which I say: I'm still developing it _(tm)_.

The dockerfile pulls from the alpine image and aims to use as minimal packages as possible to keep the project liteweight.

##### Database Handling

The Database module wraps queries around a connection and sharelock class, where monitors are used to aleviate possible stress upon the database itself. The adapter sifts through config parameters (which should not be, but can be altered by the user) and only allows valid parameters to be passed to the configuration.

##### Data Extraction

The http client wrapper seeks to deal with _most_ external issues with request and response. There are two key data sources at this current time, which are not ideal but due to the free nature of them they will have to do. Reddit is the shill source, namely some famous subreddits around investing (WSB), as well as google to extract ticker information. Both extraction methods utilize some simple regex to extract tickers, strike prices, mentions and further. Reddit shill sourcing is used to identify plausible trends which could influence where the bot focuses its time.

Defined tickers are favoured when scraping for trends and reddit shill sourcing has to be explicitly set to be factored into the bot analysis. Each ticker is run on its own thread and there are some minor preventative methods to manage resource allocation on the machine the task is run on but, it will require improvement if someone attempts to look at too many tickers.

##### Logger

I like loggers and I like trying to write my own. It's nothing special but it handles I/O streams quite well.
