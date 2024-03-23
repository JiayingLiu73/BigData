/*
Author: Student_23068191
Date: 2024-03-11
Content: SQL Queries for CourseWork One
*/

SET search_path = 'cash_equity', "$user", public;

/*
The query counts the number of liquid stocks of every sector in every country.
*/
SELECT COUNT(DISTINCT symbol) AS number_of_liquid_stocks, gics_sector, country 
FROM equity_static
WHERE symbol IN (SELECT symbol_id FROM equity_prices
				GROUP BY symbol_id
				HAVING AVG(volume)>1000000)
GROUP BY gics_sector, country
ORDER BY number_of_liquid_stocks DESC;

/*
The query calculates the average daily returns of each trader’s portfolio 
on and after 2023-10-27 and ranks their performance.
*/
SELECT (SUM(net_amount*exchange_rate*(1+avg_return))/SUM(net_amount*exchange_rate))-1 
AS port_avg_daily_return, trader_name
FROM portfolio_positions INNER JOIN (
    SELECT AVG((close_price-open_price)/open_price) AS avg_return, symbol_id  
    FROM equity_prices
    WHERE cob_date >= '2023-10-27'
    GROUP BY symbol_id) AS daily_return
ON portfolio_positions.symbol = daily_return.symbol_id 
INNER JOIN trader_static
ON trader_static.trader_id = portfolio_positions.trader
INNER JOIN (
    SELECT from_currency,to_currency,exchange_rate FROM exchange_rates
    WHERE cob_date='2023-10-27' AND to_currency='USD') AS rates_on_date
ON portfolio_positions.ccy=rates_on_date.from_currency
GROUP BY trader_name
ORDER BY port_avg_daily_return DESC;
