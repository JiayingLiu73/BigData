/*
Author: Student_23068191
Date: 2024-03-15
Content: NoSQL - MongoDB Queries for CourseWork One
*/

mongosh
use Equity

/*
This query calculates the average dividend yield of stocks that have betas lower than one in every GICS sector.
*/
db.CourseworkOne.aggregate([{$match:{'MarketData.Beta':{$lt:1.00}}}, {$group:{_id:'$StaticData.GICSSector',Average_Dividend_Yield:{$avg:'$FinancialRatios.DividendYield'}}},{$sort:{Average_Dividend_Yield:-1}}])

/*
The query obtains the average PE ratio and average beta in each sector after excluding stocks that gives too many dividends.
*/
db.CourseworkOne.aggregate([{$match:{'FinancialRatios.DividendYield':{$lt:2.0}}},{$group:{_id:'$StaticData.GICSSector',Average_PERatio:{$avg:'$FinancialRatios.PERatio'},Average_Beta:{$avg:'$MarketData.Beta'}}},{$sort:{ Average_PERatio:-1}}])