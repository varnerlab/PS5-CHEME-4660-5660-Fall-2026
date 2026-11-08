# The PS5 public checks for the Standard track.
#
# Each check is a named tuple with two fields:
#   name - what the check tests, as the checker prints it
#   test - the function that runs the check; it returns true when the check passes
# run_public_check in test/Rubric.jl runs one check. Each check calls one student function, so
# an unfinished function does not block the checks of the others.
import Distributions # the Black-Scholes check of the call premium

# The test month, as in the course example: a one-month call 2% out of the money.
const PS5_TEST = (S = 100.0, K = 102.0, T = 1/12, σ = 0.20, r = 0.0415);

"""
    ps5_reference_premium(model, S, K, T, σ, r) -> Float64

The premium the course `binomial_premium` function gives for one contract type, with the CRR
tree and 60 steps, as the docstrings ask.
"""
function ps5_reference_premium(model, S::Float64, K::Float64, T::Float64, σ::Float64, r::Float64)::Float64

    # The fund sells calls (sense -1) and buys puts (sense 1) -
    sense = model === MyAmericanCallContractModel ? -1 : 1;
    contract = build(model, (K = K, sense = sense, copy = 1, premium = 0.0));
    return binomial_premium(contract; method = :crr, h = 60, T = T, σ = σ, Sₒ = S, μ = r);
end

"""
    ps5_black_scholes_call(S, K, T, σ, r) -> Float64

The Black-Scholes value of a European call. An American call on a stock without dividends has
the same value, so a 60-step tree is close to it.
"""
function ps5_black_scholes_call(S::Float64, K::Float64, T::Float64, σ::Float64, r::Float64)::Float64

    # The two standard normal arguments of the Black-Scholes formula, then the formula -
    d1 = (log(S / K) + (r + σ^2 / 2) * T) / (σ * sqrt(T));
    d2 = d1 - σ * sqrt(T);
    N = Distributions.Normal();
    return S * Distributions.cdf(N, d1) - K * exp(-r * T) * Distributions.cdf(N, d2);
end

# --- call_premium checks ---

"""
    check_call_tree() -> Bool

`call_premium` matches the course `binomial_premium` for an American call (CRR, 60 steps), for
the test month and for a three-month call at a higher rate, so the time and the rate must be
passed through.
"""
function check_call_tree()::Bool

    # Compare the student's premium with the course function on both calls -
    for (S, K, T, σ, r) in ((100.0, 102.0, 1/12, 0.20, 0.0415), (80.0, 84.0, 0.25, 0.35, 0.08))
        expected = ps5_reference_premium(MyAmericanCallContractModel, S, K, T, σ, r);
        if !isapprox(call_premium(S, K, T, σ, r), expected; atol = 1e-10)
            return false;
        end
    end
    return true;
end

"""
    check_call_black_scholes() -> Bool

At the money, the premium is within 1% of the Black-Scholes value.
"""
function check_call_black_scholes()::Bool
    value = call_premium(50.0, 50.0, 1/12, 0.30, 0.04);
    return isapprox(value, ps5_black_scholes_call(50.0, 50.0, 1/12, 0.30, 0.04); rtol = 0.01);
end

"""
    check_call_scaling() -> Bool

Doubling the share price and the strike doubles the premium.
"""
function check_call_scaling()::Bool
    (; S, K, T, σ, r) = PS5_TEST;
    return isapprox(call_premium(2S, 2K, T, σ, r), 2 * call_premium(S, K, T, σ, r); rtol = 1e-9);
end

"""
    check_call_type_and_volatility() -> Bool

`call_premium` returns one positive `Float64`, and a higher volatility gives a higher premium.
"""
function check_call_type_and_volatility()::Bool
    (; S, K, T, r) = PS5_TEST;
    low = call_premium(S, K, T, 0.15, r);
    high = call_premium(S, K, T, 0.40, r);
    return low isa Float64 && low > 0 && high > low;
end

# --- covered_call_month checks ---

"""
    _month_matches(result, ratio::Float64, cash::Float64) -> Bool

Return `true` when `result` is the `NamedTuple` `(ratio = ..., cash = ...)` of two `Float64` values
close to the expected ratio and cash.
"""
function _month_matches(result, ratio::Float64, cash::Float64)::Bool

    # The shape and the types of the result come first, then its values -
    return result isa NamedTuple && propertynames(result) == (:ratio, :cash) &&
        result.ratio isa Float64 && result.cash isa Float64 &&
        isapprox(result.ratio, ratio; atol = 1e-12) && isapprox(result.cash, cash; atol = 1e-8);
end

"""
    check_month_worthless() -> Bool

Below the strike the calls expire worthless. With N_S = 1000 shares at S_start = 100, cash
C = 5000, K = 102, 𝒫 = 0.87, and 𝒟 = 1.00345, the premium goes into the cash and grows, so the
cash ends at 1.00345·(5000 + 870), and the ratio is (1000·99.66 + cash)/(1000·100 + 5000).
"""
function check_month_worthless()::Bool

    # The premium goes into the cash, and the cash grows for the month -
    cash = 1.00345 * (5000.0 + 1000 * 0.87);
    return _month_matches(covered_call_month(1000, 100.0, 99.66, 102.0, 0.87, 1.00345, 5000.0),
        (1000 * 99.66 + cash) / (1000 * 100.0 + 5000.0), cash);
end

"""
    check_month_exercised() -> Bool

Above the strike the calls are exercised: the fund sells its shares at K and buys new ones at
S_end, so its cash falls by N_S·(S_end - K) after it grows. With 𝒟 = 1.5, a share price of 110
or 150 gives the same ratio, (1000·102 + 1.5·(5000 + 870))/105000, but different cash.
"""
function check_month_exercised()::Bool

    # The cash after it grows, and the ratio, which stops rising at the strike -
    grown = 1.5 * (5000.0 + 1000 * 0.87);
    ratio = (1000 * 102.0 + grown) / 105000.0;

    # Two closing prices above the strike give the same ratio and different cash -
    return _month_matches(covered_call_month(1000, 100.0, 110.0, 102.0, 0.87, 1.5, 5000.0),
            ratio, grown - 1000 * (110.0 - 102.0)) &&
        _month_matches(covered_call_month(1000, 100.0, 150.0, 102.0, 0.87, 1.5, 5000.0),
            ratio, grown - 1000 * (150.0 - 102.0));
end

"""
    check_month_carries_cash() -> Bool

Two months in a row, the second starting with the first month's cash: the fund opens having
borrowed 2000, its calls are exercised in the first month, and expire in the second. The two
ratios multiply to the final wealth over the initial wealth, and the final cash is the cash
carried through both months.
"""
function check_month_carries_cash()::Bool

    # Run the first month; the second month needs the first month's cash -
    first = covered_call_month(500, 100.0, 110.0, 102.0, 0.87, 1.004, -2000.0);
    if !(first isa NamedTuple && propertynames(first) == (:ratio, :cash))
        return false;
    end

    # Run the second month from the first month's cash -
    second = covered_call_month(500, 110.0, 105.0, 113.0, 1.10, 1.004, first.cash);
    if !(second isa NamedTuple && propertynames(second) == (:ratio, :cash))
        return false;
    end

    # The expected cash after each month, and the fund's wealth at the start and at the end -
    cash_1 = 1.004 * (-2000.0 + 500 * 0.87) - 500 * (110.0 - 102.0);
    cash_2 = 1.004 * (cash_1 + 500 * 1.10);
    W_1, W_3 = 500 * 100.0 - 2000.0, 500 * 105.0 + cash_2;

    # The cash of both months, and the product of the two ratios -
    return isapprox(first.cash, cash_1; atol = 1e-8) && isapprox(second.cash, cash_2; atol = 1e-8) &&
        isapprox(first.ratio * second.ratio, W_3 / W_1; atol = 1e-12);
end

"""
    check_month_type() -> Bool

`covered_call_month` returns the NamedTuple `(ratio = ..., cash = ...)` of two `Float64`
values. With no cash and 𝒟 = 1 at the strike, both cases agree: (102 + 1)/100 = 1.03 and cash
100·1 = 100.
"""
function check_month_type()::Bool
    return _month_matches(covered_call_month(100, 100.0, 102.0, 102.0, 1.0, 1.0, 0.0), 1.03, 100.0);
end

# --- growth_rate checks ---

"""
    check_growth_one_ratio() -> Bool

One ratio of 1.1 over half a year gives 2·ln(1.1).
"""
function check_growth_one_ratio()::Bool
    return isapprox(growth_rate([1.1], 0.5), 2 * log(1.1); atol = 1e-12);
end

"""
    check_growth_product() -> Bool

Several ratios give the log of their product divided by T.
"""
function check_growth_product()::Bool
    ratios = [1.02, 0.97, 1.05, 1.01, 0.99, 1.03];
    return isapprox(growth_rate(ratios, 0.5), log(prod(ratios)) / 0.5; atol = 1e-12);
end

"""
    check_growth_flat() -> Bool

Ratios of exactly 1 give a growth rate of 0, and a loss gives a negative rate.
"""
function check_growth_flat()::Bool
    return isapprox(growth_rate(ones(6), 0.5), 0.0; atol = 1e-12) && growth_rate([0.9, 1.0], 1.0) < 0;
end

"""
    check_growth_type_and_inputs() -> Bool

`growth_rate` returns one `Float64` and does not change the ratios.
"""
function check_growth_type_and_inputs()::Bool

    # Call the function, then compare the value and the ratios with what they should be -
    ratios = [1.04, 0.95, 1.10];
    value = growth_rate(ratios, 0.25);
    return value isa Float64 && isapprox(value, log(prod([1.04, 0.95, 1.10])) / 0.25; atol = 1e-12) &&
        ratios == [1.04, 0.95, 1.10];
end

"""
    standard_public_checks() -> Vector{NamedTuple}

The twelve Standard public checks: four for each of `call_premium`, `covered_call_month`, and
`growth_rate`.
"""
function standard_public_checks()::Vector{NamedTuple}
    return NamedTuple[
        (name = "Call premium: matches the course binomial tree (CRR, 60 steps)", test = check_call_tree),
        (name = "Call premium: within 1% of Black-Scholes at the money", test = check_call_black_scholes),
        (name = "Call premium: doubling the share price and strike doubles it", test = check_call_scaling),
        (name = "Call premium: one positive Float64 that rises with volatility", test = check_call_type_and_volatility),
        (name = "Covered call month: calls expire worthless, premium into the cash", test = check_month_worthless),
        (name = "Covered call month: exercised calls paid from the grown cash", test = check_month_exercised),
        (name = "Covered call month: cash carried from one month to the next", test = check_month_carries_cash),
        (name = "Covered call month: returns (ratio, cash) as Float64 values", test = check_month_type),
        (name = "Growth rate: one ratio over half a year", test = check_growth_one_ratio),
        (name = "Growth rate: log of the product of the ratios over T", test = check_growth_product),
        (name = "Growth rate: zero for flat ratios, negative for a loss", test = check_growth_flat),
        (name = "Growth rate: one Float64; ratios unchanged", test = check_growth_type_and_inputs),
    ];
end
