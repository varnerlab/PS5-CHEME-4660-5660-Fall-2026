# PS5 Standard responses

**Central question:** Does a covered call fund beat simply holding the shares,
and what does it give up?

Answer between each question's `<!-- answer-N:start -->` and
`<!-- answer-N:end -->` markers, replacing the TODO. Label each part with its
letter, keep it to a few sentences, and cite numbers from `results/Report.md`.
Growth rates are in 1/yr.

## 1. What does the model promise?

**a. Predict** (before writing code; accuracy is not graded). On how many of
the 29 tickers will the covered call fund grow faster than holding the shares
over the half-year? Will the market's call premiums be larger or smaller than the
model's premiums at the historical volatility? Why?

**b. What the fund gives up.** In **The fund and holding the shares in the
model**, compare the fund with calls priced at implied volatility with
holding: the average mean growth rate, the probability of a negative growth
rate, and the probability that the fund beats holding. Then use **Strike choice in the
model**: how does a farther strike change each of these, and why?

**c. Pricing the call.** In **Premiums: model and market**, which pricing
volatility gives premiums closer to the market's, on average? Name one ticker
where the premium at the historical volatility is far from the market's, and
explain the gap with its two volatilities.

<!-- answer-1:start -->
TODO: Answer parts a, b, and c.
<!-- answer-1:end -->

## 2. What happened?

**a. Winners and losers.** On how many tickers did the fund beat holding the
shares, and how many did the model expect? Using **Each ticker**, what
separates the tickers where the fund won from those where it lost? Cite the
growth rates of holding and the months called away.

**b. Promise versus outcome.** Name the two tickers whose outcomes were rarest
under the model (percentile nearest 0% or 100%). What did their shares do that
the model did not expect, and what does that say about the drift and
volatility the model took from the year before? The model prices each
simulated call at its implied volatility, not at the market's mid price; could
that also play a part?

<!-- answer-2:start -->
TODO: Answer parts a and b.
<!-- answer-2:end -->

## 3. What can we conclude?

**a. Answer the central question.** Compare the fund with holding the shares,
SPY, and cash in **Growth rates and benchmarks**: the average, the median, the lowest,
and the highest growth rate. What did the fund give up, what did it get, and
how much did selling at the bid cost? Did your prediction hold?

**b. One half-year.** All 29 funds ran over the same half-year. Using the SPY
row, describe the market over these dates, and give two reasons why this
result is weaker evidence than 29 separate half-years would be.

<!-- answer-3:start -->
TODO: Answer parts a and b.
<!-- answer-3:end -->
