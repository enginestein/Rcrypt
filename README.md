# Rcrypt
A Cryptocompare API wrapper for R

Installation
------------

You can install `rcrypt` from github with:

``` r
# install.packages("devtools")
devtools::install_github("enginestein/Rcrypt")
```

Usage
-----

This package comes with several functions that map directly to CryptoCompare [API endpoints](https://min-api.cryptocompare.com). These functions center on price and other coin details for various Rcryptcurrencies. CryptoCompare integrates with several exchanges and the exchange to be queried can often be requested. However, the default exchange of CCCAGG often works the best. The following outlines common use cases for various functions.

``` r
library(Rcrypt)
```

### Available Exchanges

Possible exchanges to query can be requested using the `get_exchanges()` function. This returns a comprehensive tibble of available exchanges along with each market available on that exchange.

``` r
exchanges <- get_exchanges()
head(exchanges)
#> # A tibble: 6 x 3
#>   exchange coin  market
#>   <chr>    <chr> <chr> 
#> 1 Cryptsy  42    BTC   
#> 2 Cryptsy  42    XRP   
#> 3 Cryptsy  RDD   LTC   
#> 4 Cryptsy  RDD   USD   
#> 5 Cryptsy  RDD   XRP   
#> 6 Cryptsy  RDD   BTC
```

In this case, the `exchange` column contains the name of the exchange while the `coin` column contains the coin and the `market` column contains the market supported for `coin` on a given `exchange`. All possible exchanges can be identified by running `unique(get_exchanges()$exchage)`.

### Available Coins

All coins supported by the API and correspanding details can be obtained using the `get_coins()` function.

``` r
coins <- get_coins()
head(coins)
#> # A tibble: 6 x 16
#>       id url      image_url    name  symbol coin_name full_name  algorithm
#>    <int> <chr>    <chr>        <chr> <chr>  <chr>     <chr>      <chr>    
#> 1   4321 /coins/… /media/1231… 42    42     42 Coin   42 Coin (… Scrypt   
#> 2 749869 /coins/… /media/2701… 300   300    300 token 300 token… <NA>     
#> 3  33639 /coins/… /media/3520… 365   365    365Coin   365Coin (… X11      
#> 4  21227 /coins/… /media/3510… 404   404    404Coin   404Coin (… Scrypt   
#> 5  20909 /coins/… /media/3509… 611   611    SixEleven SixEleven… SHA256   
#> 6  28223 /coins/… /media/3515… 808   808    808       808 (808)  SHA256   
#> # ... with 8 more variables: proof_type <chr>, fully_premined <int>,
#> #   total_coin_supply <chr>, pre_mined_value <chr>,
#> #   total_coins_free_float <chr>, sort_order <int>, sponsored <lgl>,
#> #   is_trading <lgl>
```

### Current Price Data

There are two main functions for retreiving current price data. `get_price()` simply returns the price of the requested coins. `get_price_details()` returns current price data along with open, close, and other 24 hour price statistics. Price functions take two main parameters: `fsym(s)` and `tsym(s)`. These parameters specify the requested coin(s) (`fsym(s)`) and the currency the price is reported in (`tsym(s)`). The following examples illustrate getting price data for Bitcoin (BTC) and Etherium (ETH) in terms of US Dollars (USD).

``` r
get_price(c("BTC", "ETH"), "USD")
#> # A tibble: 2 x 3
#>   fromsymbol tosymbol  price
#>   <chr>      <chr>     <dbl>
#> 1 BTC        USD      10439.
#> 2 ETH        USD        861.
```

``` r
get_price_details(c("BTC", "ETH"), "USD")
#> # A tibble: 2 x 29
#>    type market fromsymbol tosymbol flags  price lastupdate         
#>   <int> <chr>  <chr>      <chr>    <int>  <dbl> <dttm>             
#> 1     5 CCCAGG BTC        USD          2 10439. 2023-03-01 04:24:46
#> 2     5 CCCAGG ETH        USD          4   861. 2023-03-01 04:24:49
#> # ... with 22 more variables: lastvolume <dbl>, lastvolumeto <dbl>,
#> #   lasttradeid <int>, volumeday <dbl>, volumedayto <dbl>,
#> #   volume24hour <dbl>, volume24hourto <dbl>, openday <dbl>,
#> #   highday <dbl>, lowday <dbl>, open24hour <dbl>, high24hour <dbl>,
#> #   low24hour <dbl>, lastmarket <chr>, change24hour <dbl>,
#> #   changepct24hour <dbl>, changeday <dbl>, changepctday <dbl>,
#> #   supply <dbl>, mktcap <dbl>, totalvolume24h <dbl>,
#> #   totalvolume24hto <dbl>
```

### Historical Price Data

Historical price data can be retreived using `get_historical_price()`. Price can be obtained at the daily, hourly, or minute level. Minute level data is only available for the past 7 days. Anything beyond 7 days must be either daily or hourly data. The following example demonstrates how to get NEO to USD data for the past 7 days.

*As a note, it seems that the API sometimes returns all historical entries, regardless of the limit provided.*

``` r
btc_price_history <- get_historical_price("NEO", "USD")
head(btc_price_history)
#> # A tibble: 6 x 7
#>   time                close  high   low  open volumefrom  volumeto
#>   <dttm>              <dbl> <dbl> <dbl> <dbl>      <dbl>     <dbl>
#> 1 2023-01-30 00:00:00  144.  169. 136.   167.    450127. 67979718.
#> 2 2023-01-31 00:00:00  146.  147. 131.   144.    266456. 37414174.
#> 3 2023-02-01 00:00:00  126.  147. 114.   146.    368930. 47844293.
#> 4 2023-02-02 00:00:00  122.  132.  94.0  126.    700073. 79912243.
#> 5 2023-02-03 00:00:00  124.  130. 107.   122.    247394. 29901510.
#> 6 2023-02-04 00:00:00  107.  125.  99.4  124.    304361. 33951028.
```

### Snapshot Data

CrytpoCompare provides endpoints for "snapshot data". These endpoints provide summarized data about individual coins and coin pairs.

``` r
btc_snapshot <- get_coin_snapshot(1182)
names(btc_snapshot)
#>  [1] "page_title"                    "page_description"             
#>  [3] "base_url"                      "base_image_url"               
#>  [5] "og_image_url"                  "og_image_width"               
#>  [7] "og_image_height"               "id"                           
#>  [9] "document_type"                 "h1text"                       
#> [11] "danger_top"                    "warning_top"                  
#> [13] "info_top"                      "symbol"                       
#> [15] "url"                           "base_angular_url"             
#> [17] "name"                          "image_url"                    
#> [19] "description"                   "features"                     
#> [21] "technology"                    "total_coin_supply"            
#> [23] "difficulty_adjustment"         "block_reward_reduction"       
#> [25] "algorithm"                     "proof_type"                   
#> [27] "start_date"                    "twitter"                      
#> [29] "website_url"                   "website"                      
#> [31] "last_block_explorer_update_ts" "block_number"                 
#> [33] "block_time"                    "net_hashes_per_second"        
#> [35] "total_coins_mined"             "previous_total_coins_mined"   
#> [37] "block_reward"                  "status"                       
#> [39] "white_paper"
```

``` r
get_pair_snapshot("BTC", "ETH")
#> $coin_data
#> # A tibble: 1 x 6
#>   algorithm proof_type block_number net_hashes_per_second total_coins_min…
#>   <chr>     <chr>             <int>                 <dbl>            <int>
#> 1 SHA256    PoW              511412          21528020746.         16892625
#> # ... with 1 more variable: block_reward <dbl>
#> 
#> $aggregated_data
#> # A tibble: 1 x 21
#>    type market fromsymbol tosymbol flags price lastupdate         
#>   <int> <chr>  <chr>      <chr>    <int> <dbl> <dttm>             
#> 1     5 CCCAGG BTC        ETH          4  12.5 2023-03-01 03:54:49
#> # ... with 14 more variables: lastvolume <dbl>, lastvolumeto <dbl>,
#> #   lasttradeid <dbl>, volumeday <dbl>, volumedayto <dbl>,
#> #   volume24hour <dbl>, volume24hourto <dbl>, openday <int>,
#> #   highday <dbl>, lowday <dbl>, open24hour <dbl>, high24hour <dbl>,
#> #   low24hour <dbl>, lastmarket <chr>
#> 
#> $exchange_data
#> # A tibble: 2 x 15
#>    type market        fromsymbol tosymbol flags price lastupdate         
#>   <int> <chr>         <chr>      <chr>    <int> <dbl> <dttm>             
#> 1     2 Bleutrade     BTC        ETH          1  12.5 2023-03-01 03:54:49
#> 2     2 LocalBitcoins BTC        ETH          1  12.4 2023-03-01 01:17:41
#> # ... with 8 more variables: lastvolume <dbl>, lastvolumeto <dbl>,
#> #   lasttradeid <dbl>, volume24hour <dbl>, volume24hourto <dbl>,
#> #   open24hour <dbl>, high24hour <dbl>, low24hour <dbl>
```

### Social Data

One of the most impressive features of the CryptoCompare API is the ability to query some basic social stats for a given coin. The data provided contains details about the coin's github repositories, page view data from CryptoCompare's main website, and a listing of similar coins. This data can be accessed as follows:

``` r
# Social stats for Bitcoin
eth_social_stats <- get_social(1182)
str(eth_social_stats)
#> List of 6
#>  $ similar_items         :Classes 'tbl_df', 'tbl' and 'data.frame':  10 obs. of  6 variables:
#>   ..$ id            : int [1:10] 7605 5031 3808 127356 4614 202330 5038 27368 4433 24854
#>   ..$ name          : chr [1:10] "Ethereum" "Ripple" "Litecoin" "IOTA" ...
#>   ..$ full_name     : chr [1:10] "Ethereum (ETH)" "Ripple (XRP)" "Litecoin (LTC)" "IOTA (IOT)" ...
#>   ..$ image_url     : chr [1:10] "/media/20646/eth_logo.png" "/media/19972/ripple.png" "/media/19782/litecoin-logo.png" "/media/1383540/iota_logo.png" ...
#>   ..$ url           : chr [1:10] "/coins/eth/" "/coins/xrp/" "/coins/ltc/" "/coins/iot/" ...
#>   ..$ following_type: int [1:10] 1 1 1 1 1 1 1 1 1 1
#>  $ cryptopian_followers  :Classes 'tbl_df', 'tbl' and 'data.frame':  11 obs. of  5 variables:
#>   ..$ id       : int [1:11] 793242 542859 787925 607981 793225 721781 793179 793172 669752 793138 ...
#>   ..$ name     : chr [1:11] "zhanglunkai1013" "captainbutters00" "johansistemas15" "rodrigo.gallego" ...
#>   ..$ image_url: chr [1:11] "https://images.cryptocompare.com/793242/993f8fd6-2de9-4a47-9c98-fda824300c05.jpg" "https://images.cryptocompare.com/542859/63929c86-be0f-47fb-939b-b146398afef3.jpg" "https://images.cryptocompare.com/787925/f35f3d6f-571c-49f7-bbfa-1e54b2f7b1d5.jpg" "https://images.cryptocompare.com/607981/50114a79-d8f0-4b7f-84f3-c4983045d0f5.jpg" ...
#>   ..$ url      : chr [1:11] "/profile/zhanglunkai1013/" "/profile/captainbutters00/" "/profile/johansistemas15/" "/profile/rodrigo.gallego/" ...
#>   ..$ type     : chr [1:11] "Cryptopian" "Cryptopian" "Cryptopian" "Cryptopian" ...
#>  $ page_views            :Classes 'tbl_df', 'tbl' and 'data.frame':  8 obs. of  2 variables:
#>   ..$ page : chr [1:8] "overview" "markets" "analysis" "charts" ...
#>   ..$ views: int [1:8] 14516361 1036994 679524 4779403 440181 50035 3089168 42486
#>  $ crypto_compare_summary:Classes 'tbl_df', 'tbl' and 'data.frame':  1 obs. of  5 variables:
#>   ..$ points    : int 3490360
#>   ..$ followers : int 52666
#>   ..$ posts     : int 47524
#>   ..$ comments  : int 98561
#>   ..$ page_views: int 24634152
#>  $ social_media          :List of 3
#>   ..$ Twitter :Classes 'tbl_df', 'tbl' and 'data.frame': 1 obs. of  9 variables:
#>   .. ..$ following       : int 127
#>   .. ..$ account_creation: int 1313643968
#>   .. ..$ name            : chr "Bitcoin"
#>   .. ..$ lists           : int 6362
#>   .. ..$ statuses        : int 19537
#>   .. ..$ favourites      : int 241
#>   .. ..$ followers       : int 792646
#>   .. ..$ link            : chr "https://twitter.com/bitcoin"
#>   .. ..$ points          : int 824475
#>   ..$ Reddit  :Classes 'tbl_df', 'tbl' and 'data.frame': 1 obs. of  10 variables:
#>   .. ..$ posts_per_hour    : num 11.2
#>   .. ..$ comments_per_hour : num 157
#>   .. ..$ posts_per_day     : num 270
#>   .. ..$ comments_per_day  : num 3766
#>   .. ..$ name              : chr "Bitcoin"
#>   .. ..$ link              : chr "https://www.reddit.com/r/bitcoin/"
#>   .. ..$ active_users      : int 9370
#>   .. ..$ community_creation: int 1284042626
#>   .. ..$ subscribers       : int 755430
#>   .. ..$ points            : int 791072
#>   ..$ Facebook:Classes 'tbl_df', 'tbl' and 'data.frame': 1 obs. of  6 variables:
#>   .. ..$ likes        : int 37288
#>   .. ..$ link         : chr "https://www.facebook.com/bitcoins/"
#>   .. ..$ is_closed    : chr "false"
#>   .. ..$ talking_about: int 163
#>   .. ..$ name         : chr "Bitcoin P2P Cryptocurrency"
#>   .. ..$ points       : int 37288
#>  $ repo_summary          :Classes 'tbl_df', 'tbl' and 'data.frame':  4 obs. of  18 variables:
#>   ..$ created_at         : int [1:4] 1363239994 1384835603 1304525025 1292771803
#>   ..$ open_total_issues  : int [1:4] 28 224 25 902
#>   ..$ parent             : logi [1:4] NA NA NA NA
#>   ..$ size               : int [1:4] 1174 17220 3003 85755
#>   ..$ closed_total_issues: int [1:4] 139 1294 11528 987
#>   ..$ stars              : int [1:4] 761 2089 2420 28498
#>   ..$ last_update        : POSIXct[1:4], format: "2023-02-27 14:56:00" ...
#>   ..$ forks              : int [1:4] 267 1372 786 16892
#>   ..$ url                : chr [1:4] "https://github.com/petertodd/python-bitcoinlib" "https://github.com/bitcoinj/bitcoinj" "https://github.com/bitcoinjs/bitcoinjs-lib" "https://github.com/bitcoin/bitcoin"
#>   ..$ closed_issues      : int [1:4] 46 621 3154 404
#>   ..$ closed_pull_issues : int [1:4] 93 673 8374 583
#>   ..$ fork               : chr [1:4] "false" "false" "false" "false"
#>   ..$ last_push          : int [1:4] 1519197806 1519839412 1519115258 1519873006
#>   ..$ source             : logi [1:4] NA NA NA NA
#>   ..$ open_pull_issues   : int [1:4] 13 24 295 8
#>   ..$ language           : chr [1:4] "Python" "Java" "JavaScript" "C++"
#>   ..$ subscribers        : int [1:4] 96 275 162 3036
#>   ..$ open_issues        : int [1:4] 15 200 607 17
```

### Pairs Data

Details about top cryptocurrency pairs (by volume) can be retrived using `get_top_pairs()`.

``` r
# Top ETH pairs
get_top_pairs("ETH")
#> # A tibble: 5 x 5
#>   exchange from_symbol to_symbol volume24h volume24h_to
#>   <chr>    <chr>       <chr>         <dbl>        <dbl>
#> 1 CCCAGG   ETH         BTC         444023.       36448.
#> 2 CCCAGG   ETH         USD         218294.   188899250.
#> 3 CCCAGG   ETH         USDT        194037.   168134922.
#> 4 CCCAGG   ETH         KRW          43634. 42774963078.
#> 5 CCCAGG   ETH         EUR          38286.    27117875.
```

### API Limits

The API has hour, minute, and second call rate limits. These limits, along with calls made against the limit, can be retrieved using `get_api_limit()` as follows:

``` r
# Second limit
get_api_limit("second")
#> # A tibble: 2 x 5
#>   call_metric histo price  news strict
#>   <chr>       <int> <int> <int>  <int>
#> 1 calls_made      0     1     0      0
#> 2 calls_left     15    49     5      1

# Minute limit
get_api_limit("minute")
#> # A tibble: 2 x 5
#>   call_metric histo price  news strict
#>   <chr>       <int> <int> <int>  <int>
#> 1 calls_made      1     5     0      0
#> 2 calls_left    299   995   100     20

# Hour limit
get_api_limit("hour")
#> # A tibble: 2 x 5
#>   call_metric histo  price  news strict
#>   <chr>       <int>  <int> <int>  <int>
#> 1 calls_made     10     31     4      2
#> 2 calls_left   7990 149969  2996    498
```
