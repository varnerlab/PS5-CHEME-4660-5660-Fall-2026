# PS5 Standard: complete the 3 functions below.
# The report calls these functions for every ticker, every month, and every simulated path.
# Keep the function names, arguments, return types, and docstrings.
# Replace each error("Complete ...") expression with your calculation.
# The return statements are supplied.
# Save your code, then run from the PS5 folder:
# julia --project=. --startup-file=no check_submission.jl
#
# Each docstring ends with Course references: the cell of the course example
# "A Covered Call Fund on a Hypothetical Stock" that does the same calculation, and the matching
# slide in the PS5 mathematical companion. The example cells wrap their
# calculation in a let ... end block. Copy only the lines you need and rename
# variables to match this file.

"""
    call_premium(S::Float64, K::Float64, T::Float64, σ::Float64, r::Float64) -> Float64

Price the one-month American call the fund sells, on the CRR binomial tree.

### Arguments

- `S`: Share price when the call is sold (USD/share).
- `K`: Strike price (USD/share).
- `T`: Time to expiration (years).
- `σ`: Volatility used to price the call (annualized decimal).
- `r`: Continuously compounded risk-free rate (1/yr).

### Returns

- `𝒫`: The call's premium (USD/share), a positive number.

### Method

Build one short American call with the course `build` function and
`MyAmericanCallContractModel`: strike `K`, `sense = -1`, `copy = 1`, and
`premium = 0.0` (the premium is what we are computing). Then price the call with the
course `binomial_premium` function: `method = :crr`, `h = 60` steps, time `T`,
volatility `σ`, share price `Sₒ = S`, and rate `μ = r`.

### Course references

- Course example "A Covered Call Fund on a Hypothetical Stock", Task 2: the lines that build
  `call` and compute `𝒫` inside the main loop.
- PS5 companion: slide 4, 'Pricing the monthly call'.
"""
function call_premium(S::Float64, K::Float64, T::Float64, σ::Float64, r::Float64)::Float64

    # TODO 1: Build one short American call with strike K.
    # Hint: build(MyAmericanCallContractModel, (K = ..., sense = -1, copy = 1, premium = 0.0)).
    call = error("Complete call_premium: build the short call.");

    # TODO 2: Price the call on the CRR binomial tree with 60 steps.
    # Hint: binomial_premium(call; method = :crr, h = 60, T = ..., σ = ..., Sₒ = ..., μ = ...).
    𝒫 = error("Complete call_premium: price the call with binomial_premium.");

    return 𝒫;
end

"""
    covered_call_month(N_S::Int, S_start::Float64, S_end::Float64, K::Float64, 𝒫::Float64,
        𝒟::Float64, C::Float64) -> NamedTuple

Run the covered call fund for one month, and compute the growth of its wealth,
`W(j+1)/W(j)`, and its cash at the end of the month.

### Arguments

- `N_S`: Shares the fund holds (shares). The fund sells one call contract for every
  100 shares, so the fund's calls cover all `N_S` shares.
- `S_start`: Share price at the start of the month, when the calls are sold (USD/share).
- `S_end`: Share price at the end of the month, when the calls expire (USD/share).
- `K`: The calls' strike price (USD/share).
- `𝒫`: The call premium, collected at the start of the month (USD/share).
- `𝒟`: Accumulation factor that grows the cash over the month (dimensionless,
  at least 1).
- `C`: The fund's cash at the start of the month, before the fund sells the calls
  (USD). Negative when the fund has borrowed.

### Returns

- `(ratio = ..., cash = ...)`: `ratio` is the fund's wealth at the end of the
  month divided by its wealth at the start, and `cash` is the fund's cash at the end
  of the month, after the calls are settled (USD, negative when the fund has
  borrowed). The report passes `cash` in as `C` for the next month.

### Method

Follow the main loop of the course example, in the same order:

1. The wealth at the start of the month, before the fund sells the calls, is
   the fund's shares plus the fund's cash: `W_start = N_S*S_start + C`.
2. The premium goes into the cash: `C + N_S*𝒫`.
3. Over the month, the cash, including the premium, earns the risk-free rate
   (on a loan, the fund pays the risk-free rate), so the cash is multiplied by `𝒟`.
4. When `S_end > K`, the calls are exercised: the fund sells its shares to the
   call buyers at `K` and buys `N_S` new shares at `S_end`, so the fund's cash falls by
   the payoff `N_S*(S_end - K)⁺`. Otherwise the calls expire worthless.
5. The wealth at the end of the month is `W_end = N_S*S_end + cash`, and
   `ratio = W_end/W_start`.

### Course references

- Course example "A Covered Call Fund on a Hypothetical Stock", Task 2: the
  lines of the main loop from `W_start` to `fund_ratio[j, p]`.
- PS5 companion: slide 5, 'One month of the covered call fund'.
"""
function covered_call_month(N_S::Int, S_start::Float64, S_end::Float64, K::Float64, 𝒫::Float64,
    𝒟::Float64, C::Float64)::NamedTuple

    # TODO 1: The fund's wealth at the start of the month, before the fund sells the calls: shares plus cash.
    # Hint: N_S*S_start + C.
    W_start = error("Complete covered_call_month: compute the wealth at the start of the month.");

    # TODO 2: The premium goes into the cash.
    # Hint: C + N_S*𝒫.
    C_premium = error("Complete covered_call_month: add the premium to the cash.");

    # TODO 3: Over the month, the cash, including the premium, earns the risk-free rate.
    # Hint: 𝒟*C_premium.
    C_grown = error("Complete covered_call_month: grow the cash for one month.");

    # TODO 4: At expiration, pay the calls' payoff: sell the shares at K, buy new shares at S_end.
    # Hint: C_grown - N_S*max(S_end - K, 0.0).
    cash = error("Complete covered_call_month: pay the calls' payoff from the cash.");

    # TODO 5: The wealth at the end of the month, and the ratio W(j+1)/W(j).
    # Hint: W_end = N_S*S_end + cash, then W_end/W_start.
    ratio = error("Complete covered_call_month: compute the ratio W(j+1)/W(j).");

    return (ratio = ratio, cash = cash);
end

"""
    growth_rate(ratios::Vector{Float64}, T::Float64) -> Float64

Compute the growth rate of the fund's wealth over a period from its monthly
wealth ratios.

### Arguments

- `ratios`: The fund's wealth ratios `W(j+1)/W(j)`, one for each part of the
  period, in any order (dimensionless, positive).
- `T`: The length of the period (years).

### Returns

- `g`: The growth rate (1/yr): the log of the final wealth over the initial
  wealth, divided by `T`.

### Method

The final wealth over the initial wealth is the product of the ratios, so the
log of the product is the sum of the logs of the ratios: `g = sum(log.(ratios)) / T`. Do not
change `ratios`.

### Course references

- Course example "A Covered Call Fund on a Hypothetical Stock", Task 3: the line that computes
  `fund_g`.
- PS5 companion: slide 6, 'The growth rate over a roll'.
"""
function growth_rate(ratios::Vector{Float64}, T::Float64)::Float64

    # TODO 1: Add up the logs of the ratios.
    # Hint: sum(log.(ratios)).
    log_growth = error("Complete growth_rate: add up the logs of the ratios.");

    # TODO 2: Divide by the length of the period.
    # Hint: log_growth / T.
    g = error("Complete growth_rate: divide by T.");

    return g;
end
