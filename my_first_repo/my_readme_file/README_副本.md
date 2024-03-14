# My first coursework

- [My first coursework](#my-first-coursework)
  - [Introduction](#introduction)
  - [Brief description of SQL vs NoSQL database](#brief-description-of-sql-vs-nosql-database)
  - [SQL Query explain](#sql-query-explain)
    -[SQL Query 1](#sql-query-1)
    -[SQL Query 2](#sql-query-2)
  - [NoSQL Query explain](#nosql-query-explain)
    -[NoSQL Query 1](#nosql-query-1)
    -[NoSQL Query 2](#nosql-query-2)
  - [Conclusion](#conclusion)

## Introduction

Large databases contain rich information. By utilizing different query tools, one can extract the information of interest from various types of databases. This report demonstrates writer’s familiarity with the SQL and NoSQL query languages by using the languages to complete the following tasks: evaluating sectors’ liquidity, assessing performance of different fund managers and providing insights including sector dividend yields, growth potential and sector risk for different types of investors.

## Brief description of SQL vs NoSQL database
One SQL and one NoSQL database are presented in the report, both containing financial data. SQL database has six tables. Table one contains different stocks’ financial data such as symbols, prices, and trading volumes. Table two has stock static including stocks’ region, sector and industry. Table three records exchange rate between various currencies on various dates. Table four stores portfolio positions data of five traders such as net quantity and currency. Table five and six are about the traders, their funds and trader limits.

NoSQL database has one collection. Each document has an id, a symbol and three objects called StaticData, MarketData and FinancialRatio respectively. StaticData contains the company names, their sectors, SECfilings and industries. MarketData includes price, market capitalization and beta of each stock. FinancialRatio records dividend yield, PE ratio and Payout ratio of every stock.

## SQL Query explain
### SQL Query 1
Background:
Different industry sectors have different features such as liquidity. Same sector in different countries could also behave differently. To gives investors an insight about sector liquidity, this query will assess the liquidity of different sectors in different countries.

Aims:
The query counts the number of liquid stocks of every sector in every country.

Approach:
The query first excludes illiquid stocks whose average daily trading volume is not larger than one million. It then groups the data by sector and country and count the number of liquid stocks in each group and ranks the numbers.

```

SET search_path = 'cash_equity', "$user", public;

```

Search path is set in advance.

```
SELECT … 
FROM equity_static
WHERE symbol IN (SELECT symbol_id FROM equity_prices
        GROUP BY symbol_id
        HAVING AVG(volume)>1000000)
…
```

For illustration purpose, ‘…’ is used to represent some commands that will be explained in other parts so focus can be placed on presented commands. 

The query first filters the data in equity_static and retain only data of liquid stocks. To do this, WHERE command is needed and it retains data whose symbol is in the selected list. The symbols in the list are selected from equity_prices and the list contains stock symbols that has an average daily trading volume of more than one million. To find such stock symbols, the equity_prices is first grouped by symbol_id so that each group has many daily trading volumes of only one stock. Then it uses HAVING and the AVG function to exclude the group that does not have an average daily trading volume of one million. Now the symbols selected from the remaining groups are the liquid stocks’ symbol.

```
SELECT COUNT(DISTINCT symbol) AS number_of_liquid_stocks, gics_sector, country 
FROM equity_static
WHERE symbol IN (…)
GROUP BY gics_sector, country
ORDER BY number_of_liquid_stocks DESC;
```

After the filter, all presented stocks are liquid. The query then uses GROUP BY command to group the data by sector and country. In each group, it counts the number of distinct stock symbol so that it can obtain the number of liquid stocks in this group. It also renames the number as number_of_liquid_stock using AS command. Finally, after counting number of liquid stocks in every group, it uses ORDER BY command to rank the numbers in descending order.

Output:
The query produces a list of sectors, countries, and numbers of liquid stocks, with the first row showing data with the largest number of liquid stocks. It can be concluded that Information Technology sector in the US has the most liquid stocks, which means it may suffer less from liquidity risk than other sectors in other countries. Investors who are concerned with liquidity risk could invest in the top 5 sectors in the corresponding countries.

### SQL Query 2
Background: 
In real life, many investors do not have time to build their own portfolio. They often seek a fund manager to manage investment on their behalf. Therefore, it is crucial to find a fund manager who is capable of gaining returns for their investment portfolios. A query is needed to assess the profitability of each fund manager’s portfolio so that their ability could be examined. The database has six traders, with one of them having no portfolio positions data. Therefore, only the five fund managers with available data will be evaluated.

Aims:
The query calculates the average daily returns of each trader’s portfolio after 2023-10-27 and ranks their performance.

Approach:
To reach the aim, the query merges portfolio_positions with chosen data in equity_prices, trader_static and exchange rates. Then it converts the net amount of each position into dollars amount. Finally, it groups the data by traders, obtain the average daily return of each trader’s portfolio after 2023-10-27 and ranks the traders by average returns.

```
SELECT AVG((close_price-open_price)/open_price) AS avg_return, symbol_id  
FROM equity_prices
WHERE cob_date >= '2023-10-27'
GROUP BY symbol_id
```

This statement extracts all stock symbols and their corresponding average daily returns after 2023-10-27 from equity_prices. It filters out data before 2023-10-27 because the date when trader’s positions are recorded in portfolio_positions is 2023-10-27. Then it groups the data by stock symbol. In each group, the data contains daily open prices and close prices of one stock. Daily returns are calculated by dividing the difference between close price and open price by open price in one day. After averaging all daily returns in one group, average daily return of one stock is obtained. Therefore, this statement gives distinct stock symbols and their average daily returns.

```
SELECT … FROM portfolio_positions INNER JOIN (
SELECT AVG((close_price-open_price)/open_price) AS avg_return, symbol_id  
FROM equity_prices
WHERE cob_date >= '2023-10-27'
GROUP BY symbol_id) AS daily_return
ON portfolio_positions.symbol = daily_return.symbol_id 
```

This statement joins the results from last statement with portfolio_positions. It renames the result table as daily_return, and symbol_id in the table can be considered as primary key. Then it inner joins two tables using stock symbols so that for each stock in portfolio_positions, it has a corresponding average daily return.

```
…
INNER JOIN trader_static
ON trader_static.trader_id = portfolio_positions.trader
…
```

This statement continues to join the portfolio_positions with another table, trader_static. In trader_static, trader_id is the primary key and each trader_id has a distinct trader name. By inner joining the two tables using trader id, we can know the name under each trader id in portfolio_positions.

```
…
INNER JOIN (
SELECT from_currency,to_currency,exchange_rate FROM exchange_rates
WHERE cob_date='2023-10-27' AND to_currency='USD') AS rates_on_date
ON portfolio_positions.ccy=rates_on_date.from_currency

…
```

This statement has two parts. First part is inside the bracket. It filters the data so that the remaining data’s cob_rate is only 2023-10-27 and to_currency is only USD. Then it selects from_currency, to_currency and exchange rates from the data. The second part is outside the bracket. It renamed result table as rates_on_date. It also inner joins the two tables so ccy in portfolio_positions is linked with from_currency in rates_on_date. In this way, we can know the exchange rate between every available currency and USD on 2023-10-27.

```
SELECT (SUM(net_amount*exchange_rate*(1+avg_return))/SUM(net_amount*exchange_rate))-1 
AS port_avg_daily_return, trader_name
FROM portfolio_positions ….
….
GROUP BY trader_name
ORDER BY port_avg_daily_return DESC;
```

After merging the information from other three tables, the merged portfolio_position now has its original data and trader name, exchange rate and average daily return of every stock. The statement first groups the data by trader name so every group has positions in the portfolio of only one trader. In every group, it calculates the portfolio value, which is the sum of dollar amounts of all positions in the portfolio on 2023-10-27. This is done by multiplying net_amount by exchange rate and summing all the results. It also calculates the sum of dollar amounts of all positions after one day. This is done by multiplying net_amount, exchange_rate and one plus average daily return of corresponding stock then summing all the results. By dividing the portfolio value after one day by the value on 2023-10-17 and then subtracting one, average daily return of portfolio of one trader is obtained.

After getting distinct trader name and their corresponding portfolio average daily return, the query uses ORDER BY command to rank the traders from the highest average daily portfolio return to the lowest.

Output:
This query yields two columns, one showing the traders’ name and the other listing the average daily returns of their portfolios. The returns can be seen as a measurement of the ability of each trader. It can be shown that only John Black manages to produce a positive daily return. Therefore, among the five traders, John Black has outstanding performance and investors is recommended to invest in his fund.

## NoSQL Query explain
### NoSQL Query 1
Background: Different investors have different investment objectives and risk preferences. Investors who are about to retire may want low risk stocks that yield high dividends as a source of income after retirement. To help determine which sector provides more dividends after excluding the risky stocks, a query is needed.

Aims:
This query calculates the average dividend yield of stocks that have betas lower than one in every GICS sector.

Approach:
To obtain the average dividend yield of less risky stocks in every sector, this query retains stocks that are less volatile than the market and groups them by sector to calculate the average dividend yield.

```
mongsh
use MongoCW1
```

After the database is build and before the query, mongo shell is activated and the database is accessed.

```
db.cw1.aggregate([{$match:{'MarketData.Beta':{$lt:1.00}}},{$group:{_id:'$StaticData.GICSSector',Average_Dividend_Yield:{$avg:'$FinancialRatios.DividendYield'}}},{$sort:{Average_Dividend_Yield:-1}}])
```

This statement first filters out documents that have beta larger than or equal to one, meaning that only stocks that are less risky than markets can remain. It then groups the filtered data by GICS sectors and for each sector, it calculates the average of dividend yield. Finally, it ranks the average dividend yield in descending order.

Output:
The result is a list of GISC sectors and their corresponding average dividend yield after excluding the risky stocks. It gives investors an expected dividend yield if they invest in less risky stocks in one of the sectors in the output. Energy, Real Estate, Utilities, Consumer Staples and Financials are the top five sectors. Energy sector the highest dividend yield, which is 4.7. Investors are recommended to invest in the Energy sector if they prefer high dividends.

### NoSQL Query 2
Background: 
Young investors who still have a long investment horizon may prefer growth stocks that is riskier but have high potential for generating large returns. A query that evaluates growth potential and corresponding risk in each sector is required if they want to select a sector to invest in.

Aims:
The query obtains the average PE ratio and average beta in each sector after excluding stocks that gives too many dividends.

Approach:
As growth companies usually do not give out too many dividends, the query first filters out stocks that have relatively high dividend yield. Then it groups the documents by GICS sector and determine the average PE ratio and beta in each group. Since growth stocks often have high PE ratio, this ratio can be used to assess the growth potential in every sector.

```
db.cw1.aggregate([{$match:{'FinancialRatios.DividendYield':{$lt:2.0}}},{$group:{_id:'$StaticData.GICSSector',Average_PERatio:{$avg:'$FinancialRatios.PERatio'},Average_Beta:{$avg:'$MarketData.Beta'}}},{$sort:{ Average_PERatio:-1}}])
```

This statement first checks whether a document has a dividend yield lower than 2.0 and filters out all documents that do not satisfy the condition. After that, it groups the remaining data by GISC sectors. It then obtains the average PE ratio and average beta for each group and lists the results by ranking average PE ratio in descending order.

Output:
The query produces a list of sectors and their corresponding PE ratios and betas after excluding stocks that is not growth stocks. Information Technology sector has the highest PE ratio. It also has a beta of about 1.28, suggesting high risk in the sector. Investors can use the results to evaluate the risk and potential of growth companies in one sector so that they can make more informed investment decision.

## Conclusion
In conclusion, this report shows the process of getting financial information from raw data. It assesses the liquidity of every sector in every country and obtains the results that Information Technology in the US has a better liquidity. It also evaluates the returns generating ability of five traders and find the best one with positive average daily return. Using NoSQL database, the report examines the stock markets for both young investors and investors who are near retirement. It summarizes that Information Technology sector has high risk and high growth potential, and Energy sector is a better choice for receiving large dividends.
