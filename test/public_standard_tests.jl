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
    for (S, K, T, σ, r) in ((100.0, 102.0, 1/12, 0.20, 0.0415), (80.0, 84.0, 0.25, 0.35, 0.08))
        expected = ps5_reference_premium(MyAmericanCallContractModel, S, K, T, σ, r);
        isapprox(call_premium(S, K, T, σ, r), expected; atol = 1e-10) || return false;
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

# --- covered_call_ratio checks ---

"""
    check_ratio_worthless() -> Bool

Below the strike the call expires worthless: the fund keeps the shares and the premium grown
for the month. With S_start = 100, S_end = 99.66, K = 102, 𝒫 = 0.87, 𝒟 = 1.00345, the ratio is
(99.66 + 1.00345·0.87)/100.
"""
function check_ratio_worthless()::Bool
    value = covered_call_ratio(100.0, 99.66, 102.0, 0.87, 1.00345);
    return isapprox(value, (99.66 + 1.00345 * 0.87) / 100; atol = 1e-12);
end

"""
    check_ratio_exercised() -> Bool

Above the strike the call is exercised: the shares less the payoff are worth the strike, so
the ratio stops at (K + 𝒟·𝒫)/S_start however high the share price goes.
"""
function check_ratio_exercised()::Bool
    a = covered_call_ratio(100.0, 110.0, 102.0, 0.87, 1.00345);
    b = covered_call_ratio(100.0, 150.0, 102.0, 0.87, 1.00345);
    expected = (102.0 + 1.00345 * 0.87) / 100;
    return isapprox(a, expected; atol = 1e-12) && isapprox(b, expected; atol = 1e-12);
end

"""
    check_ratio_growth_factor() -> Bool

The premium is multiplied by 𝒟, not divided: with 𝒟 = 1.5 and 𝒫 = 2, a month that ends at the
starting price of 50 gives (50 + 3)/50.
"""
function check_ratio_growth_factor()::Bool
    return isapprox(covered_call_ratio(50.0, 50.0, 55.0, 2.0, 1.5), 53.0 / 50.0; atol = 1e-12);
end

"""
    check_ratio_type() -> Bool

`covered_call_ratio` returns one `Float64`, and at the strike both cases agree.
"""
function check_ratio_type()::Bool
    value = covered_call_ratio(100.0, 102.0, 102.0, 1.0, 1.0);
    return value isa Float64 && isapprox(value, 1.03; atol = 1e-12);
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
    ratios = [1.04, 0.95, 1.10];
    value = growth_rate(ratios, 0.25);
    return value isa Float64 && isapprox(value, log(prod([1.04, 0.95, 1.10])) / 0.25; atol = 1e-12) &&
        ratios == [1.04, 0.95, 1.10];
end

"""
    standard_public_checks() -> Vector{NamedTuple}

The twelve Standard public checks: four for each of `call_premium`, `covered_call_ratio`, and
`growth_rate`.
"""
function standard_public_checks()::Vector{NamedTuple}
    return NamedTuple[
        (name = "Call premium: matches the course binomial tree (CRR, 60 steps)", test = check_call_tree),
        (name = "Call premium: within 1% of Black-Scholes at the money", test = check_call_black_scholes),
        (name = "Call premium: doubling the share price and strike doubles it", test = check_call_scaling),
        (name = "Call premium: one positive Float64 that rises with volatility", test = check_call_type_and_volatility),
        (name = "Covered call ratio: call expires worthless below the strike", test = check_ratio_worthless),
        (name = "Covered call ratio: capped at the strike plus the premium", test = check_ratio_exercised),
        (name = "Covered call ratio: premium grown by the accumulation factor", test = check_ratio_growth_factor),
        (name = "Covered call ratio: one Float64 at the strike", test = check_ratio_type),
        (name = "Growth rate: one ratio over half a year", test = check_growth_one_ratio),
        (name = "Growth rate: log of the product of the ratios over T", test = check_growth_product),
        (name = "Growth rate: zero for flat ratios, negative for a loss", test = check_growth_flat),
        (name = "Growth rate: one Float64; ratios unchanged", test = check_growth_type_and_inputs),
    ];
end
