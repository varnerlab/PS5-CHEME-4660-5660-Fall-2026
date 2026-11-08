# The PS5 public checks for the Advanced track: the twelve Standard checks plus four for each
# collar function. See test/public_standard_tests.jl for the check format.

"""
    ps5_black_scholes_put(S, K, T, σ, r) -> Float64

The Black-Scholes value of a European put. An American put is worth at least this much.
"""
function ps5_black_scholes_put(S::Float64, K::Float64, T::Float64, σ::Float64, r::Float64)::Float64

    # Put-call parity gives the put from the call -
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

    # Compare the student's premium with the course function on both puts -
    for (S, K, T, σ, r) in ((100.0, 92.0, 1/12, 0.25, 0.0415), (100.0, 105.0, 0.5, 0.30, 0.07))
        expected = ps5_reference_premium(MyAmericanPutContractModel, S, K, T, σ, r);
        if !isapprox(put_premium(S, K, T, σ, r), expected; atol = 1e-10)
            return false;
        end
    end
    return true;
end

"""
    check_put_american() -> Bool

A deep in-the-money American put is worth at least its exercise value, K - S, and at least the
European value; it is an American put, not a European one.
"""
function check_put_american()::Bool

    # An American put must be worth its exercise value of 40, and more than the European put -
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

# --- collar_month checks ---

"""
    _collar_grown(N_S, 𝒫₁, 𝒫₂, 𝒟, C) -> Float64

Return the cash after the net premium goes in and grows for the month, for the collar checks.
"""
_collar_grown(N_S, 𝒫₁, 𝒫₂, 𝒟, C) = 𝒟 * (C + N_S * (𝒫₂ - 𝒫₁));

"""
    check_collar_between() -> Bool

Between the strikes neither option pays: with N_S = 1000, cash 5000, 𝒫₁ = 0.40 (put), 𝒫₂ =
1.10 (call), and 𝒟 = 1.004, the cash ends at 1.004·(5000 + 1000·0.70).
"""
function check_collar_between()::Bool

    # Neither option pays, so the cash only takes in the net premium and grows -
    cash = _collar_grown(1000, 0.40, 1.10, 1.004, 5000.0);
    return _month_matches(collar_month(1000, 100.0, 97.0, 92.0, 105.0, 0.40, 1.10, 1.004, 5000.0),
        (1000 * 97.0 + cash) / 105000.0, cash);
end

"""
    check_collar_floor() -> Bool

Below the put's strike the fund exercises its puts: it sells its shares at K₁ and buys new ones,
so its cash rises by N_S·(K₁ - S_end). The ratio stops falling at the put's strike, so the
ratio is the same at 80 and at 50, but the cash differs.
"""
function check_collar_floor()::Bool

    # The cash after it grows, and the ratio, which stops falling at the put's strike -
    grown = _collar_grown(1000, 0.40, 1.10, 1.004, 5000.0);
    ratio = (1000 * 92.0 + grown) / 105000.0;

    # Two closing prices below the put's strike give the same ratio and different cash -
    return _month_matches(collar_month(1000, 100.0, 80.0, 92.0, 105.0, 0.40, 1.10, 1.004, 5000.0),
            ratio, grown + 1000 * (92.0 - 80.0)) &&
        _month_matches(collar_month(1000, 100.0, 50.0, 92.0, 105.0, 0.40, 1.10, 1.004, 5000.0),
            ratio, grown + 1000 * (92.0 - 50.0));
end

"""
    check_collar_cap() -> Bool

Above the call's strike the calls are exercised and the cash falls by N_S·(S_end - K₂). The
ratio is capped, the same at 120 and at 200, but the cash differs.
"""
function check_collar_cap()::Bool

    # The cash after it grows, and the ratio, which stops rising at the call's strike -
    grown = _collar_grown(1000, 0.40, 1.10, 1.004, 5000.0);
    ratio = (1000 * 105.0 + grown) / 105000.0;

    # Two closing prices above the call's strike give the same ratio and different cash -
    return _month_matches(collar_month(1000, 100.0, 120.0, 92.0, 105.0, 0.40, 1.10, 1.004, 5000.0),
            ratio, grown - 1000 * (120.0 - 105.0)) &&
        _month_matches(collar_month(1000, 100.0, 200.0, 92.0, 105.0, 0.40, 1.10, 1.004, 5000.0),
            ratio, grown - 1000 * (200.0 - 105.0));
end

"""
    check_collar_net_debit() -> Bool

When the put costs more than the call brings in, the net premium lowers the cash: with
N_S = 200, borrowed cash -3000, 𝒫₁ = 2, 𝒫₂ = 0.5, and 𝒟 = 1.5, from 110 to 100, the cash ends
at 1.5·(-3000 - 200·1.5) = -4950, and the ratio is (200·100 - 4950)/(200·110 - 3000). It
returns `(ratio = ..., cash = ...)` as `Float64` values.
"""
function check_collar_net_debit()::Bool
    return _month_matches(collar_month(200, 110.0, 100.0, 95.0, 115.0, 2.0, 0.5, 1.5, -3000.0),
        (20000.0 - 4950.0) / 19000.0, -4950.0);
end

"""
    advanced_public_checks() -> Vector{NamedTuple}

The twenty Advanced public checks: the twelve Standard checks, then four for `put_premium` and
four for `collar_month`.
"""
function advanced_public_checks()::Vector{NamedTuple}
    return vcat(standard_public_checks(), NamedTuple[
        (name = "Put premium: matches the course binomial tree (CRR, 60 steps)", test = check_put_tree),
        (name = "Put premium: an American put, at least its exercise value", test = check_put_american),
        (name = "Put premium: doubling the share price and strike doubles it", test = check_put_scaling),
        (name = "Put premium: one positive Float64 that rises with volatility", test = check_put_type_and_volatility),
        (name = "Collar month: net premium into the cash between the strikes", test = check_collar_between),
        (name = "Collar month: the put pays into the cash below its strike", test = check_collar_floor),
        (name = "Collar month: capped at the call's strike; call payoff from the cash", test = check_collar_cap),
        (name = "Collar month: a net premium paid lowers the cash; Float64 values", test = check_collar_net_debit),
    ]);
end
