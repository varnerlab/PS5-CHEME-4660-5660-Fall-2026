# The PS5 public checks for the Advanced track: the twelve Standard checks plus four for each
# collar function. See test/public_standard_tests.jl for the check format.

"""
    ps5_black_scholes_put(S, K, T, σ, r) -> Float64

The Black-Scholes value of a European put. An American put is worth at least this much.
"""
function ps5_black_scholes_put(S::Float64, K::Float64, T::Float64, σ::Float64, r::Float64)::Float64
    return ps5_black_scholes_call(S, K, T, σ, r) - S + K * exp(-r * T);
end

# --- put_premium checks ---

"""
    check_put_tree() -> Bool

`put_premium` matches the course `binomial_premium` for an American put (CRR, 60 steps), for
a one-month put below the share price and for a six-month put at a higher rate whose value
lies above its exercise value, so the time and the rate must be passed through.
"""
function check_put_tree()::Bool
    for (S, K, T, σ, r) in ((100.0, 92.0, 1/12, 0.25, 0.0415), (100.0, 105.0, 0.5, 0.30, 0.07))
        expected = ps5_reference_premium(MyAmericanPutContractModel, S, K, T, σ, r);
        isapprox(put_premium(S, K, T, σ, r), expected; atol = 1e-10) || return false;
    end
    return true;
end

"""
    check_put_american() -> Bool

A deep in-the-money American put is worth at least its exercise value, K - S, and at least the
European value; it is an American put, not a European one.
"""
function check_put_american()::Bool
    value = put_premium(60.0, 100.0, 1.0, 0.20, 0.10);
    european = ps5_black_scholes_put(60.0, 100.0, 1.0, 0.20, 0.10);
    return value >= 40.0 - 1e-9 && value > european + 1e-3;
end

"""
    check_put_scaling() -> Bool

Doubling the share price and the strike doubles the premium.
"""
function check_put_scaling()::Bool
    return isapprox(put_premium(200.0, 184.0, 1/12, 0.25, 0.0415),
        2 * put_premium(100.0, 92.0, 1/12, 0.25, 0.0415); rtol = 1e-9);
end

"""
    check_put_type_and_volatility() -> Bool

`put_premium` returns one positive `Float64`, and a higher volatility gives a higher premium.
"""
function check_put_type_and_volatility()::Bool
    low = put_premium(100.0, 92.0, 1/12, 0.15, 0.0415);
    high = put_premium(100.0, 92.0, 1/12, 0.40, 0.0415);
    return low isa Float64 && low > 0 && high > low;
end

# --- collar_ratio checks ---

"""
    check_collar_between() -> Bool

Between the strikes neither option pays: the shares plus the net premium grown for the month.
"""
function check_collar_between()::Bool
    value = collar_ratio(100.0, 97.0, 92.0, 105.0, 0.40, 1.10, 1.004);
    return isapprox(value, (97.0 + 1.004 * (1.10 - 0.40)) / 100; atol = 1e-12);
end

"""
    check_collar_floor() -> Bool

Below the put's strike the fund is worth the floor K₁, however far the share price falls.
"""
function check_collar_floor()::Bool
    expected = (92.0 + 1.004 * (1.10 - 0.40)) / 100;
    return isapprox(collar_ratio(100.0, 80.0, 92.0, 105.0, 0.40, 1.10, 1.004), expected; atol = 1e-12) &&
        isapprox(collar_ratio(100.0, 50.0, 92.0, 105.0, 0.40, 1.10, 1.004), expected; atol = 1e-12);
end

"""
    check_collar_cap() -> Bool

Above the call's strike the fund is worth the cap K₂, however far the share price rises.
"""
function check_collar_cap()::Bool
    expected = (105.0 + 1.004 * (1.10 - 0.40)) / 100;
    return isapprox(collar_ratio(100.0, 120.0, 92.0, 105.0, 0.40, 1.10, 1.004), expected; atol = 1e-12) &&
        isapprox(collar_ratio(100.0, 200.0, 92.0, 105.0, 0.40, 1.10, 1.004), expected; atol = 1e-12);
end

"""
    check_collar_net_debit() -> Bool

When the put costs more than the call brings in, the net premium is a cost: with 𝒫₁ = 2,
𝒫₂ = 0.5, and 𝒟 = 1.5 at an unchanged price of 100, the ratio is (100 - 1.5·1.5)/100. It
returns one `Float64`.
"""
function check_collar_net_debit()::Bool
    value = collar_ratio(100.0, 100.0, 95.0, 110.0, 2.0, 0.5, 1.5);
    return value isa Float64 && isapprox(value, (100.0 - 1.5 * 1.5) / 100; atol = 1e-12);
end

"""
    advanced_public_checks() -> Vector{NamedTuple}

The twenty Advanced public checks: the twelve Standard checks, then four for `put_premium` and
four for `collar_ratio`.
"""
function advanced_public_checks()::Vector{NamedTuple}
    return vcat(standard_public_checks(), NamedTuple[
        (name = "Put premium: matches the course binomial tree (CRR, 60 steps)", test = check_put_tree),
        (name = "Put premium: an American put, at least its exercise value", test = check_put_american),
        (name = "Put premium: doubling the share price and strike doubles it", test = check_put_scaling),
        (name = "Put premium: one positive Float64 that rises with volatility", test = check_put_type_and_volatility),
        (name = "Collar ratio: shares plus net premium between the strikes", test = check_collar_between),
        (name = "Collar ratio: floored at the put's strike", test = check_collar_floor),
        (name = "Collar ratio: capped at the call's strike", test = check_collar_cap),
        (name = "Collar ratio: a net premium paid lowers the ratio; one Float64", test = check_collar_net_debit),
    ]);
end
