# PS5 price model: simulate monthly share prices with geometric Brownian motion, as in the
# course example "A Covered Call Fund on SPY" (Task 1).
using Dates, Random, VLQuantitativeFinancePackage

"""
    monthly_prices(plan::NamedTuple, number_of_months::Int, config::NamedTuple, index::Int) -> Matrix{Float64}

Simulate the share price at the start of each month under geometric Brownian
motion with the trailing drift and volatility in `plan`. A month lasts
`plan.term`, the first trade's time to expiration.

### Arguments

- `plan`: The `plan` of one ticker's roll, from `ticker_rolls`, with `S0`, `μ`, and `σ̂`.
- `number_of_months`: How many one-month calls the fund sells.
- `config`: The settings from `load_config`.
- `index`: The ticker's position in the list of rolls. The random number
  generator is reseeded with `config.seed + index`, so every run gives the same paths.

### Returns

- `S`: a `(number_of_months + 1) × config.number_of_paths` matrix. `S[j, p]` is
  the share price on path `p` at the start of month `j`; the last row is the
  price at the end of the last month (USD/share).
"""
function monthly_prices(plan::NamedTuple, number_of_months::Int, config::NamedTuple, index::Int)::Matrix{Float64}

    # The GBM model of the share price under our belief -
    Random.seed!(config.seed + index);
    model = build(MyGeometricBrownianMotionEquityModel, (μ = plan.μ, σ = plan.σ̂));

    # Rows are months; column 1 is the time, so we drop it -
    paths = VLQuantitativeFinancePackage.sample(model, (T₁ = 0.0, T₂ = number_of_months * plan.term,
        Δt = plan.term, Sₒ = plan.S0); number_of_paths = config.number_of_paths);
    return Matrix{Float64}(paths[:, 2:end]);
end

"""
    roll_prices(roll::NamedTuple, config::NamedTuple, index::Int) -> NamedTuple

Simulate the share price on the real roll's own dates, for the comparison of the
model's promise with what happened. Each trade lasts its real `days`, and the days
between an expiration and a later entry are simulated too, so the simulated roll
spans the same time as the real one. The drift and volatility are the trailing
values in `roll.plan`.

### Arguments

- `roll`: One ticker's roll, from `ticker_rolls`.
- `config`: The settings from `load_config`.
- `index`: The ticker's position in the list of rolls. The random number
  generator is reseeded with `config.seed + 1000 + index`.

### Returns

- `(start, finish)`: two `length(roll.months) × config.number_of_paths`
  matrices. `start[j, p]` is the simulated share price on path `p` when trade
  `j` enters, and `finish[j, p]` when it expires (USD/share).
"""
function roll_prices(roll::NamedTuple, config::NamedTuple, index::Int)::NamedTuple

    # Initialize -
    Random.seed!(config.seed + 1000 + index);
    μ, σ = roll.plan.μ, roll.plan.σ̂;
    months = roll.months;
    number_of_months, number_of_paths = length(months), config.number_of_paths;
    start = zeros(number_of_months, number_of_paths);
    finish = zeros(number_of_months, number_of_paths);
    step(S, years) = S .* exp.((μ - σ^2 / 2) * years .+ σ * sqrt(years) .* randn(number_of_paths));

    # One GBM step for each trade, and one for each gap before the next trade -
    S = fill(roll.plan.S0, number_of_paths);
    for j in 1:number_of_months
        if j > 1
            gap_days = Dates.value(months[j].entry - months[j-1].expiration);
            S = gap_days > 0 ? step(S, gap_days / PS5_CALENDAR_DAYS) : S;
        end
        start[j, :] = S;
        S = step(S, months[j].days / PS5_CALENDAR_DAYS);
        finish[j, :] = S;
    end
    return (start = start, finish = finish);
end
