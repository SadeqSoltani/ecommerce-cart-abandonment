# E-Commerce Cart Abandonment Analysis

**Predicting and reducing cart abandonment from clickstream behavior** :
 Built on the RetailRocket e-commerce dataset (2.4M events, May to September 2015)

---

## Overview

Roughly three out of four online shopping carts are abandoned. This project takes five months of raw e-commerce clickstream data (2.4 million events) and works it end to end: from raw event logs in PostgreSQL, through exploratory and funnel analysis, into a leakage-free predictive model in Python, and finally into an interactive Power BI dashboard and a set of business recommendations.

The guiding question throughout: **where do we lose shoppers, what signals real buying intent, and which carts can we save?**

Every figure in this project is expressed in **counts and rates, never dollars**. The dataset is fully anonymized and contains no prices or revenue (see *Data & limitations*), so the analysis is deliberately honest about what it can and cannot claim.

---

## Key findings

**1. The funnel leaks at the top, not the bottom.**
Only **2.60%** of product views become carts, but **32.39%** of carts convert to purchase. The problem is getting shoppers to commit, not closing them once they do. Effort is better spent on discovery and availability than on checkout.

**2. Out-of-stock inventory silently bleeds demand.**
In-stock items are carted almost **10x more often** than out-of-stock ones (4.48% vs 0.45% view-to-cart). And roughly **40% of all product views** land on items that are unavailable. That is an enormous volume of shopper attention flowing to things they cannot buy.

**3. How someone shops predicts intent better than what they shop for.**
Engaged buyers browse **2.4x more categories** (3.03 vs 1.25) and stay **4x longer** (29.89 vs 7.26 minutes) than non-buyers. A model using only behavioral signals roughly **doubles** the ability to rank carts by purchase likelihood versus chance.

---

## Dashboard

**1. Executive Summary: headline KPIs and the view to cart to purchase funnel**

<img width="1313" height="731" alt="01_executive_summary" src="https://github.com/user-attachments/assets/7b29cca6-378d-48ab-b2cd-84e17454526d" />




**2. Funnel: cart-to-purchase rate by day of week and hour of day**

<img width="1309" height="735" alt="02_funnel" src="https://github.com/user-attachments/assets/369030c2-d26f-4f78-bd20-b57b6c7a7b72" />




**3. Availability: the 10x conversion gap and the ~40% of views hitting out-of-stock items**

<img width="1307" height="735" alt="03_availability" src="https://github.com/user-attachments/assets/b3d92339-c72e-423b-8bfe-8c41a0cb916e" />




**4. Customer Journey: buyers vs non-buyers on category breadth and session duration**

<img width="1304" height="731" alt="04_customer_journey" src="https://github.com/user-attachments/assets/8b36bcad-e40f-4718-9408-ce0ed8b03627" />


---

## The predictive model

The modeling task: given an add-to-cart event, predict whether it converts to a purchase in the same session, using only features available **at the moment of carting**.

**Setup**
- **Grain:** one row per add-to-cart event (69,332 carts)
- **Label:** purchased in the same session (27.3% positive, so 72.7% abandonment)
- **Split:** time-based (train on May to July, test on August to September). A random split would leak future information; splitting on time does not.
- **Models:** Logistic Regression (baseline) and XGBoost
- **Metric:** PR-AUC as the headline (appropriate for the class balance), with a random baseline of 0.258

**Results (test set)**

| Model | PR-AUC | ROC-AUC |
|---|---|---|
| Random baseline | 0.258 | 0.500 |
| Logistic Regression | 0.485 | 0.701 |
| XGBoost | 0.504 | 0.718 |

The model roughly doubles ranking power over chance using behavior alone. XGBoost edges out Logistic Regression rather than dominating it, which suggests the signal is mostly linear. The ceiling here is the data, not the method: the missing variables (price, promotions, returning-customer identity) are the likely path to a stronger model.

**What drives abandonment (SHAP)**

<img width="1081" height="704" alt="shap_importance" src="https://github.com/user-attachments/assets/7de1054a-ab4b-4470-aea6-1157c72206dc" />


The behavioral signature splits cleanly in two:

- **Signals toward purchase:** time invested in the session, repeat views of the specific item, longer deliberation on that item.
- **Signals toward abandonment:** already having several carts in the session (cart-as-wishlist), browsing many different items, and popular items added on impulse.


---

## Two reconciliations

Good analysis explains its own apparent contradictions. Two are worth calling out.

**The availability paradox.** Availability is the strongest interpretable finding at the population level (the 10x funnel gap) yet the model's weakest predictor. There is no contradiction: availability does its damage upstream, at view-to-cart, so out-of-stock items rarely reach the cart stage at all. By the time we are looking at carts, about 92% are already in-stock, and a variable with almost no variance left cannot predict much. Availability shapes *whether a cart happens*; it says little about *whether an existing cart converts*.

**Exploration: engagement or distraction?** Session-level analysis shows buyers explore more; the cart-level model shows breadth predicts abandonment. Again no contradiction, because the unit of analysis differs. Across a *session*, exploring is a sign of engagement and correlates with buying. *Conditional on a specific cart*, having already spread attention across many items marks that cart as a casual add rather than a committed purchase. Same data, two questions, two correct answers.

---

## Recommendations

1. **Capture out-of-stock demand.** Add a "notify me when back in stock" option and surface stock status earlier in search and listings. Roughly 40% of view demand currently hits dead ends. Even a modest capture rate turns lost attention into a re-engagement list.
2. **Refocus optimization on the view-to-cart step**, where the real leak is, rather than on checkout, which already converts at 32%.
3. **Trigger behavior-based cart nudges.** Use the model to prioritize which carts get a cheap reassurance or urgency nudge, matched to the behavior signature (low-intent single-view carts, wishlist-style multi-cart sessions, hesitating high-deliberation carts).
4. **Enrich the data.** Capturing price, promotion, and returning-customer signals is the highest-value next step and would let future analysis speak in revenue rather than counts.

Full detail in [`notebooks/business_recommendations.md`](notebooks/business_recommendations.md).

---

## Tech stack

| Layer | Tools |
|---|---|
| **Data engineering & analysis** | PostgreSQL (sessionization, funnel, availability, feature engineering) |
| **Modeling & explainability** | Python (pandas, scikit-learn, XGBoost, SHAP) |
| **Visualization** | Power BI (interactive dashboard), matplotlib (model figures) |


---

## Data & limitations

The [RetailRocket dataset](https://www.kaggle.com/datasets/retailrocket/ecommerce-dataset) is real e-commerce clickstream data, fully anonymized. Stated openly, because honest scope is part of the analysis:

- **No prices or revenue.** All impact is in counts and rates, never dollars.
- **Everything hashed** except category ID and availability. Actions are directional, not SKU-level.
- **No customer data** (demographics, device, location, returning-customer identity). Segmentation is by in-session behavior only.
- **Shallow traffic:** about 71% of visitors have exactly one event, so intent analysis focuses on the engaged subset (2+ events).
- **Point-in-time availability:** availability is joined as-of each event, which is what makes the 10x finding trustworthy. A small number of out-of-stock purchases exist because availability flips over time.

---

## Repository structure

```
Retailrocket/
├── README.md
├── requirements.txt
├── .gitignore  
│   
├── sql/                              
│   ├── 00_create_raw_tables.sql
│   ├── 01_load_and_trim.sql
│   ├── 02_profiling.sql
│   ├── 03_events_enriched.sql
│   ├── 04_category_tree.sql
│   ├── 05_sessionization.sql
│   ├── 06_visitor_features.sql
│   ├── 07_funnel_analysis.sql
│   ├── 08_journey_analysis.sql
│   ├── 09_availability_analysis.sql
│   └── 10_cart_features.sql
├── notebooks/
│   ├── abandonment_model.ipynb      
│   └── business_recommendations.md
├── models/                           
│   ├── xgb_abandonment.pkl
│   └── scaler.pkl
└── power bi/
    │              
    ├── 01_executive_summary.png
    ├── 02_funnel.png
    ├── 03_availability.png
    ├── 04_customer_journey.png
    └── shap_importance.png
```

> **Note on large files:** the raw `data/` CSVs and the `.pbix` are excluded from the repo via `.gitignore` because they exceed GitHub's 100MB file limit. Download the data from Kaggle (see below) and open the `.pbix` locally, or use [Git LFS](https://git-lfs.com/) if you want to version them.

---

## How to reproduce

**Prerequisites:** PostgreSQL, Python 3.10+, Power BI Desktop.

**1. Get the data**

Download the [RetailRocket dataset](https://www.kaggle.com/datasets/retailrocket/ecommerce-dataset) from Kaggle and place the four CSVs in the `data/` folder.

**2. Set up credentials**

Create a `.env` file in the project root with your database details (this file is gitignored and never committed):
```
DB_USER=postgres
DB_PASSWORD=your_password_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=cleansignal
```

**3. Build the database and run the SQL pipeline**
```bash
createdb cleansignal

# Run files 00 through 10 in sequence. Each builds on the previous:
# raw tables -> load -> profiling -> enrich -> categories ->
# sessionization -> visitor features -> funnel -> journey ->
# availability -> cart_features.
psql -d cleansignal -f sql/00_create_raw_tables.sql
# ... continue through ...
psql -d cleansignal -f sql/10_cart_features.sql
```
This produces the `events_sessionized`, `session_summary`, and `cart_features` tables the rest of the project depends on.

**4. Run the modeling notebook**
```bash
pip install -r requirements.txt
jupyter notebook notebooks/abandonment_model.ipynb
```
The notebook reads the database credentials from `.env`, builds the time-based split, trains both models, evaluates them, and exports the SHAP figure.

**5. Open the dashboard**

Open `power bi/Power bi.pbix` in Power BI Desktop. It connects to the PostgreSQL tables in Import mode, so the file is self-contained once refreshed against your database.



