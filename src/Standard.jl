# PS5 Standard: complete the 3 functions below.
# The report calls these functions for every ticker, every month, and every simulated path.
# Keep the function names, arguments, return types, and docstrings.
# Replace each error("Complete ...") expression with your calculation.
# The setup lines and return statements are supplied.
# Save your code, then run from the PS5 folder:
# julia --project=. --startup-file=no check_submission.jl
#
# Each docstring ends with Course references: the cell of the course example
# "A Covered Call Fund on SPY" that does the same calculation, and the matching
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
`premium = 0.0` (the premium is what we are computing). Then price it with the
course `binomial_premium` function: `method = :crr`, `h = 60` steps, time `T`,
volatility `σ`, share price `Sₒ = S`, and rate `μ = r`.

### Course references

- Course example "A Covered Call Fund on SPY", Task 2: the lines that build
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
    covered_call_ratio(S_start::Float64, S_end::Float64, K::Float64, 𝒫::Float64, 𝒟::Float64) -> Float64

Compute the growth of the fund's wealth over one month, `W(j+1)/W(j)`, when it
owns the shares and has sold one call per share.

### Arguments

- `S_start`: Share price at the start of the month, when the call is sold (USD/share).
- `S_end`: Share price at the end of the month, when the call expires (USD/share).
- `K`: The call's strike price (USD/share).
- `𝒫`: The call's premium, collected at the start of the month (USD/share).
- `𝒟`: Accumulation factor that grows the premium, held as cash, to the end of
  the month (dimensionless, at least 1).

### Returns

- `ratio`: The fund's wealth at the end of the month divided by its wealth at
  the start, a positive number.

### Method

At the end of the month the fund owns shares worth `S_end`, owes the call's
payoff `(S_end - K)⁺`, and holds the premium grown to `𝒟·𝒫`. Its shares less
the payoff are worth `min(S_end, K)`, so the ratio is
`(min(S_end, K) + 𝒟·𝒫) / S_start`.

### Course references

- Course example "A Covered Call Fund on SPY", Task 2: the line that computes
  `fund_ratio[j, p]`.
- PS5 companion: slide 5, 'One month of the covered call fund'.
"""
function covered_call_ratio(S_start::Float64, S_end::Float64, K::Float64, 𝒫::Float64, 𝒟::Float64)::Float64

    # TODO 1: The value of the shares less the call's payoff at the end of the month.
    # Hint: min(S_end, K).
    shares_less_payoff = error("Complete covered_call_ratio: compute the shares less the call payoff.");

    # TODO 2: Add the premium grown to the end of the month, and divide by the share price at the start.
    # Hint: (shares_less_payoff + 𝒟*𝒫)/S_start.
    ratio = error("Complete covered_call_ratio: compute the ratio W(j+1)/W(j).");

    return ratio;
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

The final wealth over the initial wealth is the product of the ratios, so its
log is the sum of the logs of the ratios: `g = sum(log.(ratios)) / T`. Do not
change `ratios`.

### Course references

- Course example "A Covered Call Fund on SPY", Task 3: the line that computes
  `fund_g`.
- PS5 companion: slide 6, 'The growth rate over a roll'.
"""
function growth_rate(ratios::Vector{Float64}, T::Float64)::Float64

    # TODO 1: Add up the logs of the ratios.
    # Hint: sum(log.(ratios)).
    log_growth = error("Complete growth_rate: add up the logs of the ratios.");

    # TODO 2: Divide by the length of the period.
    g = error("Complete growth_rate: divide by T.");

    return g;
end
