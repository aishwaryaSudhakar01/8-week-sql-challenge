# 8 Week SQL Challenge

![SQL](https://img.shields.io/badge/SQL-BigQuery-4285F4?logo=googlebigquery&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)
![Case Studies](https://img.shields.io/badge/Case%20Studies-0%2F8%20Complete-lightgrey)

Working through [Danny Ma's 8 Week SQL Challenge](https://8weeksqlchallenge.com/getting-started/) to sharpen my exploratory data analysis skills, going beyond "does the query run" to actually interrogating each dataset: spotting patterns, questioning assumptions, and writing SQL that answers the business question, not just the technical one.

Eight case studies, eight industries: restaurant analytics, delivery logistics, subscription metrics, banking data, retail sales, marketing funnels, e-commerce, and digital ad trends. Each is solved end-to-end (schema setup, exploratory queries, written findings) in **BigQuery SQL**.

## Case Studies

| # | Case Study | Scenario | Status | Solution |
|---|---|---|---|---|
| 1 | [Danny's Diner](https://8weeksqlchallenge.com/case-study-1/) | A Japanese restaurant wants to understand visiting patterns, spend, and favourite menu items to improve customer experience and evaluate a loyalty program. | 🚧 In Progress | [View →](./case-study-1/README.md) |
| 2 | [Pizza Runner](https://8weeksqlchallenge.com/case-study-2/) | A pizza delivery startup ("Uber for pizza") needs data cleaned and analysed to help direct runners and optimise operations. | ⏳ Upcoming | — |
| 3 | [Foodie-Fi](https://8weeksqlchallenge.com/case-study-3/) | A Netflix-style streaming service for cooking shows wants subscription data analysed to guide future investment and feature decisions. | ⏳ Upcoming | — |
| 4 | [Data Bank](https://8weeksqlchallenge.com/case-study-4/) | A digital bank that also sells distributed data storage needs customer, transaction, and balance data analysed to forecast storage needs. | ⏳ Upcoming | — |
| 5 | [Data Mart](https://8weeksqlchallenge.com/case-study-5/) | An online supermarket needs the sales impact of a June 2020 sustainable packaging change quantified across region, platform, and customer segment. | ⏳ Upcoming | — |
| 6 | [Clique Bait](https://8weeksqlchallenge.com/case-study-6/) | An online seafood retailer wants funnel fallout rates calculated: how customers drop off between visiting, viewing, adding to cart, and purchasing. | ⏳ Upcoming | — |
| 7 | [Balanced Tree Clothing Co.](https://8weeksqlchallenge.com/case-study-7/) | A clothing retailer needs transaction, product performance, and revenue analysis to support monthly stakeholder reporting. | ⏳ Upcoming | — |
| 8 | [Fresh Segments](https://8weeksqlchallenge.com/case-study-8/) | A digital marketing agency needs aggregated ad-click interest data analysed to profile a client's customer base. | ⏳ Upcoming | — |

## Repo Structure

Each case study lives in its own folder:

```
case-study-N/
├── README.md          # schema/ERD, each question with its query + output screenshot, and findings
├── solution.sql        # full runnable SQL for the case (schema + all queries)
├── datasets/            # raw source data (CSVs) transcribed from Danny Ma's schema images
└── images/              # screenshots referenced in README.md
```

## About This Challenge

The 8 Week SQL Challenge is a free, self-paced series of business case studies created by [Danny Ma](https://www.linkedin.com/in/datawithdanny/) as part of the [Serious SQL](https://www.datawithdanny.com/) course. Each case study drops you into a different industry (food & beverage, logistics, subscriptions, fintech, retail, e-commerce, and digital marketing) with a realistic (synthetic) dataset and a set of business questions to answer using SQL alone. There are no fill-in-the-blank exercises; each case is solved from a blank schema up.

## Notes

Danny Ma provides each case's schema visually (ERD images) rather than as downloadable files, so table structures here were transcribed from the official case study pages before writing any queries. Each case's README includes the schema/ERD plus a screenshot of every query's output alongside the query itself, so results are visible without running anything.
