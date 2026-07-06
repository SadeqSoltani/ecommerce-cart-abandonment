# Business Insights & Executive Recommendations

**Project:** Cart Abandonment & Conversion Analysis (RetailRocket clickstream)

**Scope:** May to September 2015 with 2.4M events 

---

## Executive summary

We analysed five months of anonymised clickstream data to answer one question a merchandising lead would actually ask: **where do we lose shoppers, what signals real buying intent, and which carts can we save?**

Three findings carry the story:

1. **The leak is at the top of the funnel, not the bottom.** Only **2.6%** of product views become carts, but **32%** of carts convert to purchase. The problem is getting people to commit, not closing them once they do.
2. **Out-of-stock inventory is silently bleeding demand.** Roughly **40% of all product views** land on items that are unavailable, and those items are carted **around 10x less often** than in-stock ones.
3. **How someone shops predicts intent better than what they shop for.** A focused shopper, one who spends time and returns to a specific item, converts. A shopper accumulating many items across many categories is browsing, not buying. A model using *only behaviour* roughly doubles our ability to rank carts by purchase likelihood over chance.

---

## The business context

The funnel is simple: a shopper **views** a product, may **add it to cart**, and may then **purchase**. Each step is a chance to lose them. Our job was to quantify each leak, identify what behaviour separates buyers from browsers, and build a tool that flags at-risk carts early enough to act on.

The headline problem: **72.7% of carts are abandoned.** Out of 69,332 add-to-cart events, only 27.3% ended in a purchase in the same session. That is the number every recommendation here is ultimately trying to move.

---

## What the data can and cannot tell us

Stated openly, because honest scope is part of the analysis:

| Limitation | Consequence for these recommendations |
|---|---|
| **No prices or revenue** | All impact is in counts and rates. We can say "recapture this many carts," never "earn $X." |
| **Everything hashed** except category ID and availability | We can say *category 1633 converts worst*, never *what it is*. Actions are directional, not SKU-level. |
| **No customer data** (demographics, device, location, returning-customer identity) | We cannot segment by who the shopper is, only by what they did in-session. |
| **Shallow traffic**, with roughly 71% of visitors having exactly one event | Population-wide averages are dominated by one-and-done visitors, so intent analysis focuses on the *engaged* subset (2+ events). |

These are not excuses. They define exactly where the findings are solid and where a follow-up with richer data would pay off.

---

## Finding 1: The funnel leaks at the top

| Funnel stage | Conversion rate |
|---|---|
| View to Cart | **2.60%** |
| Cart to Purchase | **32.39%** |

The view-to-cart step is where the vast majority of shoppers disappear. Once an item is in the cart, roughly a third are bought, a respectable close rate. **Effort spent improving product discovery, availability, and the view experience will move far more revenue than effort spent on checkout optimisation**, because there is simply more leakage to recover upstream.

**Timing amplifies this.** Conversion is not flat across the week or day: cart-to-purchase peaks on **Wednesday (around 36%)** and dips on weekends (around 26%), and swings roughly **2.5x across the hours of the day** (times recorded in UTC; the store's local timezone is unknown, so treat the *shape* as real and the exact clock hours as approximate).

### Recommendation 1: Concentrate optimisation effort on discovery and the view-to-cart step

- **Action:** Prioritise merchandising, search/recommendation, and product-page improvements over checkout-flow tweaks. Instrument the view-to-cart step as the primary KPI.
- **How to test:** A/B test product-page changes (imagery, availability messaging, social proof) and measure the *view-to-cart* rate, not just final conversion.
- **Caveat:** The Wednesday/weekend pattern may reflect the audience mix rather than a causal "best day." Confirm before scheduling campaigns around it, and re-derive the hours in local time before acting on time-of-day.

---

## Finding 2: Out-of-stock inventory is the biggest fixable leak

Availability is one of only two un-hashed variables, which makes it the most *interpretable* and *actionable* signal in the entire project.

| Availability | Views | Carts | View to Cart |
|---|---|---|---|
| **In-stock** | 1,431,158 | 64,122 | **4.48%** |
| **Out-of-stock** | 978,877 | 4,377 | **0.45%** |

Two facts stand out:

- **In-stock items are carted almost 10x more often** (4.48% vs 0.45%). Availability at the moment of viewing is decisive.
- **Roughly 40% of all product views land on out-of-stock items** (978,877 of about 2.41M views). That is an enormous volume of shopper attention flowing to things they cannot buy.

This finding rests on a **point-in-time ("as-of") join**. For every event we retrieved the item's availability *as it was at that moment*, not its status today. That is what makes the number trustworthy rather than an artefact of stale data. (A small number of out-of-stock items still show purchases, 1,628 of them, because availability flips over time and an item can come back in stock between view and purchase. Named here so it is not mistaken for an error.)

### Recommendation 2: Capture out-of-stock demand instead of losing it

- **Action:** Add a **"notify me when back in stock"** capture on out-of-stock product pages, and surface stock status earlier in search and category listings so shoppers spend less attention on dead ends.
- **The opportunity, quantified:** Roughly 40% of view demand currently hits unavailable items. Even a modest capture rate on that traffic converts otherwise-lost attention into a re-engagement list, measurable in signups and subsequent carts, with no price data required.
- **Secondary action:** Feed the category-level out-of-stock ranking (which departments lose the most view demand to unavailability) to the inventory/planning team as a restocking-priority signal.
- **Caveat:** Some out-of-stock views are of discontinued items where a back-in-stock promise cannot be kept. The notify feature should be gated on items expected to return.

---

## Finding 3: Focus predicts purchase; accumulation predicts abandonment

Comparing **engaged** sessions (2+ events, so we are not just measuring one-and-done visitors) tells a consistent story:

| Behaviour (engaged sessions) | Non-buyers (369,018) | Buyers (13,762) | Ratio |
|---|---|---|---|
| Avg product views | 3.25 | 6.49 | 2.0x |
| Avg unique items | 2.44 | 4.87 | 2.0x |
| Avg unique categories | 1.25 | 3.03 | 2.4x |
| Avg session duration (min) | 7.26 | 29.89 | 4.1x |

At the **session** level, buyers explore more and stay longer. Exploration is a proxy for engagement.

The **predictive model** (add-to-cart level) then refines this into something more actionable. Using only behavioural signals known *at the moment of carting*, it ranks carts by purchase likelihood at **PR-AUC 0.50 vs a 0.26 random baseline**, roughly double chance. The explainability analysis (SHAP) shows two opposing behavioural signatures:

**Signals that push a cart toward PURCHASE**
- **Time invested in the session** before carting (the strongest single signal)
- **Repeat views of the specific item** being carted
- **Longer deliberation** on that item before adding it

**Signals that push a cart toward ABANDONMENT**
- **Already having several other carts** in the session (cart-as-wishlist behaviour)
- **Browsing many different items** (breadth without commitment)
- **Popular items** (added on impulse, abandoned more)

In one line: **a shopper who goes deep on one thing buys; a shopper who spreads wide and piles up carts is bookmarking.**

### Recommendation 3: Trigger the right nudge for the right behaviour

The model is a **prioritisation tool**: it tells you *which* carts to spend a cheap intervention on, and the behaviour signature tells you *which* intervention.

| Behaviour signature | What it means | Suggested intervention |
|---|---|---|
| Cart early in a short session, item viewed once | Low intent, high abandonment risk | Reassurance / urgency nudge (reviews, stock level, "still deciding?"), most room to move |
| Several carts already in the session | Cart-as-wishlist | "Ready to check out?" consolidation prompt; save-for-later framing |
| Long deliberation, repeat item views, not yet bought | Serious but hesitating | Targeted reassurance: return policy, shipping, price confidence |

- **How to test:** Deploy each nudge to the flagged segment as a hold-out A/B and measure *same-session conversion lift* against an untreated control.
- **Caveat:** The model's precision on the "will buy" class is about 43%, good enough to prioritise a **cheap, low-risk nudge**, not good enough to gate a costly or intrusive intervention. Match the cost of the action to the confidence of the flag.

---

## Two reconciliations that make these findings trustworthy

Good analysis explains its own apparent contradictions. Two are worth stating explicitly.

**The availability paradox.** Availability is the *strongest* interpretable finding at the population level (the 10x funnel gap) yet the model's *weakest* predictor. There is no contradiction: availability does its damage **upstream, at view-to-cart**, so out-of-stock items rarely reach the cart stage at all. By the time we are looking at carts, about 92% are already in-stock, and a variable with almost no variance left cannot predict much. Availability shapes *whether a cart happens*; it says little about *whether an existing cart converts*.

**Exploration: engagement or distraction?** Session-level analysis shows buyers explore more; the cart-level model shows breadth predicts abandonment. Again no contradiction, because the **unit of analysis differs**. Across a *session*, exploring is a sign of engagement and correlates with buying. *Conditional on a specific cart*, having already spread attention across many items marks that cart as a casual add rather than a committed purchase. Same data, two questions, two correct answers.

---

## What the model is, and is not, good for

- **It is** a lightweight, leakage-free **prioritisation layer**: given a cart, rank how likely it is to convert, using only what is known at that instant. Useful for targeting cheap, timely nudges.
- **It is not** a high-confidence predictor of individual outcomes. At about 43% precision on the buying class, roughly three in five carts it flags as "likely buy" still abandon. Treat its output as a **ranking**, not a verdict.
- **The ceiling is the data, not the method.** Behaviour alone roughly doubles ranking power over chance; the gap to a genuinely strong model is almost certainly the **missing variables**: price, promotions, and returning-customer identity, none of which this dataset contains.

---

## Priorities and next steps

**Do now (high confidence, low cost):**
1. Add back-in-stock capture and earlier stock-status signalling. Recovers the roughly 40% of view demand hitting dead ends (Recommendation 2).
2. Refocus optimisation effort on discovery and the view-to-cart step, where the real leak is (Recommendation 1).

**Do next (test-and-learn):**
3. Deploy behaviour-triggered cart nudges to model-flagged segments as controlled A/B tests (Recommendation 3).

**Invest to unlock more (data enrichment):**
4. Capture **price, promotion, and returning-customer** signals. These are the highest-value additions and would most likely lift the model from "doubles chance" to genuinely decision-grade, and would finally let every finding here be expressed in revenue rather than counts.

---

## Appendix: key figures at a glance

| Metric | Value |
|---|---|
| Analysis window | 3 May to 18 Sep 2015 |
| Total events | ~2.41M |
| View to Cart | 2.60% |
| Cart to Purchase | 32.39% |
| Cart abandonment rate | 72.7% (69,332 carts) |
| In-stock vs OOS view-to-cart | 4.48% vs 0.45% (~10x) |
| Share of views on OOS items | ~40% |
| Engaged buyers vs non-buyers, category breadth | 3.03 vs 1.25 (2.4x) |
| Engaged buyers vs non-buyers, session duration | 29.89 vs 7.26 min (4.1x) |
| Model PR-AUC (XGBoost) | 0.504 vs 0.258 random baseline |
| Model ROC-AUC (XGBoost) | 0.718 |
| Top purchase signals | time-in-session, item repeat-views, item deliberation time |
| Top abandonment signals | prior carts in session, browsing breadth, item popularity |


