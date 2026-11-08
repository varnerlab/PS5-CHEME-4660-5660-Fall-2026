# Supplied evaluation and report for PS5. Runs the selected student functions on the model of
# each ticker (Study 1) and on its real monthly roll (Study 2), then writes Report.md to read and
# CSV files to explore. Exported values are decimals; displayed tables use percentages for
# probabilities and premiums, and growth rates in 1/yr.
using CSV, DataFrames, Dates, Printf, Statistics, VLQuantitativeFinancePackage

# --- Calling student functions ---------------------------------------------------------------

# The first line of an error message, shortened.
function _issue_text(caught)::String
    lines = filter(!isempty, Base.strip.(split(sprint(showerror, caught), '\n')));
    text = isempty(lines) ? string(typeof(caught)) : String(first(lines));
    return length(text) > 300 ? first(text, 297) * "..." : text;
end

# Checks on what student functions return, so a wrong value is reported like an error.
function _check_premium(v)
    v isa Real && isfinite(v) && v > 0 ||
        throw(ArgumentError("it returned $(repr(v)), not a positive premium"));
    return Float64(v);
end
function _check_month(v)
    (v isa NamedTuple && propertynames(v) == (:ratio, :cash)) ||
        throw(ArgumentError("it returned $(repr(v)), not a NamedTuple (ratio = ..., cash = ...)"));
    (v.ratio isa Real && isfinite(v.ratio) && v.ratio > 0) ||
        throw(ArgumentError("it returned the ratio $(repr(v.ratio)), not a positive wealth ratio"));
    (v.cash isa Real && isfinite(v.cash)) ||
        throw(ArgumentError("it returned the cash $(repr(v.cash)), not a finite amount"));
    return (ratio = Float64(v.ratio), cash = Float64(v.cash));
end
function _check_rate(v)
    v isa Real && isfinite(v) ||
        throw(ArgumentError("it returned $(repr(v)), not a finite growth rate"));
    return Float64(v);
end

"""
    StudentCalls

A record of the student functions the report called: for each function, the tickers it was
called on, the tickers where it failed, and its first error message.
"""
struct StudentCalls
    log::Dict{Symbol,Any}
    order::Vector{Symbol}
end
StudentCalls() = StudentCalls(Dict{Symbol,Any}(), Symbol[]);

# Call one student function by name on one ticker's data. On an error, record it against the
# function and the ticker, keep the first message, and rethrow a marker so the caller can leave
# that ticker's result missing.
struct _StudentFailure <: Exception end
function _student(calls::StudentCalls, lookup::Function, name::Symbol, ticker::String,
    check::Function, args...)
    if !haskey(calls.log, name)
        calls.log[name] = (called = Set{String}(), failed = Set{String}(), first = String[]);
        push!(calls.order, name);
    end
    record = calls.log[name];
    push!(record.called, ticker);
    try
        return check(Base.invokelatest(lookup(name), args...));
    catch caught
        push!(record.failed, ticker);
        isempty(record.first) && push!(record.first, "($(ticker)): " * _issue_text(caught));
        throw(_StudentFailure());
    end
end

# Run a calculation that calls student functions; a student failure gives `missing`.
function _attempt(f::Function)
    try
        return f();
    catch caught
        caught isa _StudentFailure && return missing;
        rethrow();
    end
end

# One line per student function that failed at least once.
function _call_issues(calls::StudentCalls)::Vector{String}
    issues = String[];
    for name in calls.order
        record = calls.log[name];
        isempty(record.failed) && continue;
        n, m = length(record.failed), length(record.called);
        scope = n == m ? "all $m tickers" : "$n of $m tickers";
        push!(issues, "$(name) failed on $(scope). First error $(only(record.first))");
    end
    return issues;
end

# --- Study 1: the model ----------------------------------------------------------------------

# Summary helpers: an empty or missing input gives `missing` instead of an error or NaN.
_mean(v) = (v === missing || isempty(v)) ? missing : mean(v);
_median(v) = (v === missing || isempty(v)) ? missing : median(v);
_present(v) = collect(Float64, skipmissing(v));
_share(v) = (v === missing || isempty(v)) ? missing : mean(v);

# The opening cash of a fund (and of the holding benchmark) whose N_S shares cost S each (USD).
_opening_cash(config, S::Float64)::Float64 = config.cash_reserve * config.N_S * S;

# The wealth ratio of a simulated fund that is wiped out, a 99.9% loss. A fund whose wealth reaches
# zero or below has no growth rate, because the log of zero or a negative number is undefined.
const _WIPED_OUT_RATIO = 0.001;

# Growth rates of every simulated path for the covered call fund. Each month the fund sells the
# smallest listed strike at or above `target` times the share price, priced with the student's
# call_premium at volatility σ, and the student's covered_call_month runs the month, with the
# cash carried from one month to the next. A path stops when the fund owes more than its shares
# are worth. Also returns, for each path, whether the fund's cash ended any month negative (it
# borrowed).
function _model_fund_rates(calls, lookup, ticker, S::Matrix{Float64}, target::Float64, σ::Float64,
    Δt::Float64, increment::Float64, config)::NamedTuple
    number_of_months, number_of_paths = size(S, 1) - 1, size(S, 2);
    N_S, 𝒟, T = config.N_S, exp(config.gᵧ * Δt), number_of_months * Δt;
    rates = Vector{Float64}(undef, number_of_paths);
    borrowed = falses(number_of_paths);
    ratios = Vector{Float64}(undef, number_of_months);
    for p in 1:number_of_paths
        C = _opening_cash(config, S[1, p]); # cash at the start of the first month (USD)
        wiped_out = false; # true once the fund owes more than its shares are worth
        for j in 1:number_of_months
            K = listed_call_strike(target * S[j, p], increment);
            𝒫 = _student(calls, lookup, :call_premium, ticker, _check_premium, S[j, p], K, Δt, σ, config.gᵧ);

            # The fund's wealth at the end of this month, from the same inputs. At or below zero, the path stops -
            end_cash = 𝒟 * (C + N_S * 𝒫) - N_S * max(S[j+1, p] - K, 0.0);
            if N_S * S[j+1, p] + end_cash <= 0.0
                wiped_out = true;
                borrowed[p] = true;
                break;
            end

            month = _student(calls, lookup, :covered_call_month, ticker, _check_month,
                N_S, S[j, p], S[j+1, p], K, 𝒫, 𝒟, C);
            ratios[j] = month.ratio;
            C = month.cash; # cash at the end of the month, the start of the next (USD)
            borrowed[p] |= C < 0;
        end
        if wiped_out
            rates[p] = _student(calls, lookup, :growth_rate, ticker, _check_rate, [_WIPED_OUT_RATIO], T);
        else
            rates[p] = _student(calls, lookup, :growth_rate, ticker, _check_rate, copy(ratios), T);
        end
    end
    return (rates = rates, borrowed = borrowed);
end

# The collar fund's growth rate on every path: the same listed call as the fund at the call's
# implied volatility, and the largest listed put strike at or below the put's target, priced with
# the student's put_premium at the put's implied volatility; collar_month runs each month.
function _model_collar_rates(calls, lookup, ticker, S::Matrix{Float64}, plan, Δt::Float64,
    increment::Float64, config)::NamedTuple
    number_of_months, number_of_paths = size(S, 1) - 1, size(S, 2);
    N_S, 𝒟, T = config.N_S, exp(config.gᵧ * Δt), number_of_months * Δt;
    rates = Vector{Float64}(undef, number_of_paths);
    borrowed = falses(number_of_paths);
    ratios = Vector{Float64}(undef, number_of_months);
    for p in 1:number_of_paths
        C = _opening_cash(config, S[1, p]);
        for j in 1:number_of_months
            K₂ = listed_call_strike(plan.call_moneyness * S[j, p], increment);
            K₁ = listed_put_strike(plan.put_moneyness * S[j, p], increment);
            K₁ < K₂ || throw(ArgumentError("$(ticker): the put's listed strike is not below the call's."));
            𝒫₂ = _student(calls, lookup, :call_premium, ticker, _check_premium, S[j, p], K₂, Δt, plan.call_iv, config.gᵧ);
            𝒫₁ = _student(calls, lookup, :put_premium, ticker, _check_premium, S[j, p], K₁, Δt, plan.put_iv, config.gᵧ);
            month = _student(calls, lookup, :collar_month, ticker, _check_month,
                N_S, S[j, p], S[j+1, p], K₁, K₂, 𝒫₁, 𝒫₂, 𝒟, C);
            ratios[j] = month.ratio;
            C = month.cash;
            borrowed[p] |= C < 0;
        end
        rates[p] = _student(calls, lookup, :growth_rate, ticker, _check_rate, copy(ratios), T);
    end
    return (rates = rates, borrowed = borrowed);
end

# Growth rates of the holding benchmark on every path: the same N_S shares and opening cash as
# the fund, no calls, so the cash only grows by 𝒟 each month.
function _model_holding_rates(calls, lookup, ticker, S::Matrix{Float64}, Δt::Float64, config)::Vector{Float64}
    number_of_months, number_of_paths = size(S, 1) - 1, size(S, 2);
    N_S, 𝒟, T = config.N_S, exp(config.gᵧ * Δt), number_of_months * Δt;
    rates = Vector{Float64}(undef, number_of_paths);
    ratios = Vector{Float64}(undef, number_of_months);
    for p in 1:number_of_paths
        B = _opening_cash(config, S[1, p]); # the benchmark's cash (USD)
        for j in 1:number_of_months
            ratios[j] = (N_S * S[j+1, p] + 𝒟 * B) / (N_S * S[j, p] + B);
            B = 𝒟 * B;
        end
        rates[p] = _student(calls, lookup, :growth_rate, ticker, _check_rate, copy(ratios), T);
    end
    return rates;
end

# The wealth ratio over the days between one trade's expiration and the next entry, when the
# fund holds its N_S shares and its cash grows by 𝒟_gap; returns the ratio and the new cash.
function _gap_step(N_S::Int, S_before::Float64, S_after::Float64, 𝒟_gap::Float64, C::Float64)::NamedTuple
    return (ratio = (N_S * S_after + 𝒟_gap * C) / (N_S * S_before + C), cash = 𝒟_gap * C);
end

# Growth rates of the fund and the holding benchmark on every simulated path of the real roll:
# each trade keeps its real target (its real strike over the share price at entry), its real
# length, and its implied volatility; its strike is the smallest listed strike at or above the
# target times the simulated price, and the student's call_premium prices it. Between trades the
# fund holds its shares and cash.
function _matched_rates(calls, lookup, roll, prices, config)::NamedTuple
    months = roll.months;
    number_of_months, number_of_paths = size(prices.start);
    N_S, gᵧ = config.N_S, config.gᵧ;
    fund = Vector{Float64}(undef, number_of_paths);
    holding = Vector{Float64}(undef, number_of_paths);
    for p in 1:number_of_paths
        C = _opening_cash(config, prices.start[1, p]); # the fund's cash (USD)
        B = C; # the holding benchmark's cash (USD)
        fund_ratios = Float64[];
        holding_ratios = Float64[];
        for (j, m) in enumerate(months)
            S_start, S_end = prices.start[j, p], prices.finish[j, p];
            if j > 1 && m.gap_days > 0
                𝒟_gap = exp(gᵧ * m.gap_days / PS5_CALENDAR_DAYS);
                step = _gap_step(N_S, prices.finish[j-1, p], S_start, 𝒟_gap, C);
                push!(fund_ratios, step.ratio); C = step.cash;
                step = _gap_step(N_S, prices.finish[j-1, p], S_start, 𝒟_gap, B);
                push!(holding_ratios, step.ratio); B = step.cash;
            end
            Δt = m.days / PS5_CALENDAR_DAYS;
            𝒟 = exp(gᵧ * Δt);
            K = listed_call_strike((m.K_call / m.S_start) * S_start, roll.strike_increment);
            𝒫 = _student(calls, lookup, :call_premium, roll.ticker, _check_premium, S_start, K, Δt, m.call_iv, gᵧ);
            month = _student(calls, lookup, :covered_call_month, roll.ticker, _check_month,
                N_S, S_start, S_end, K, 𝒫, 𝒟, C);
            push!(fund_ratios, month.ratio); C = month.cash;
            push!(holding_ratios, (N_S * S_end + 𝒟 * B) / (N_S * S_start + B)); B = 𝒟 * B;
        end
        fund[p] = _student(calls, lookup, :growth_rate, roll.ticker, _check_rate, fund_ratios, roll.T);
        holding[p] = _student(calls, lookup, :growth_rate, roll.ticker, _check_rate, holding_ratios, roll.T);
    end
    return (fund = fund, holding = holding);
end

"""
    evaluate_model(track, rolls, config; lookup) -> NamedTuple

Study 1. For each ticker, simulate monthly share prices with geometric Brownian motion (the
trailing drift and volatility on its first entry date), and run a fund that holds N_S shares and
a cash account and sells calls every month. Each month's strike is the smallest listed strike at
or above the first trade's strike multiple times the share price, on the ticker's grid of listed
strikes; a month lasts the first trade's time to expiration. The calls are priced with the
student's `call_premium` every month on every path, once at the trailing (historical) volatility
and once at the call's implied volatility; the Advanced collar also buys the largest listed put
at or below the put's strike multiple, priced with `put_premium` at its implied volatility. The
holding benchmark holds the same shares and opening cash and sells no calls.

# Returns
`(tickers, strikes, differences)`. `tickers` has one row per ticker: `ticker, group,
call_moneyness, σ̂, call_iv, premium_hist, premium_iv, premium_market` (first-trade premiums as
fractions of the share price), `holding_mean, holding_sd, holding_loss` (mean, standard
deviation, and probability of a negative growth rate of the holding benchmark),
`fund_hist_mean, fund_hist_loss, fund_hist_beats, fund_hist_borrows`, the same four for
`fund_iv` (`beats`: probability that the fund grows faster than the holding benchmark;
`borrows`: probability that its cash ends a month negative), `fund_iv_sd`, and on the Advanced
track `put_moneyness, put_iv, put_premium_iv, collar_mean, collar_loss, collar_beats,
collar_borrows, collar_sd`. `strikes` has one row per ticker and target strike multiple in the
config's `moneyness_grid`, priced at the call's implied volatility: `ticker, moneyness,
difference_mean` (mean of fund minus holding growth rate), `beats`, `fund_loss`, `borrows`.
`matched_beats` is the probability that the fund beats the holding benchmark when the simulation
follows the real roll (each trade's real strike multiple, length, and implied volatility, and the
gaps between trades); `differences` maps each ticker to those simulated fund-minus-holding growth
rates, or `missing`.
"""
function evaluate_model(track::String, rolls::Vector{NamedTuple}, config::NamedTuple, calls::StudentCalls;
    lookup::Function = name -> getfield(Main, name))::NamedTuple

    rows = NamedTuple[];
    strike_rows = NamedTuple[];
    differences = Dict{String,Any}();
    advanced = track == "advanced";

    for (index, roll) in enumerate(rolls)
        plan = roll.plan;
        Δt = plan.term; # a month in the model lasts the first trade's time to expiration (years)
        ticker = roll.ticker;
        increment = roll.strike_increment;
        number_of_months = length(roll.months);
        S = monthly_prices(plan, number_of_months, config, index);
        K = plan.call_moneyness * plan.S0; # the first trade's real strike

        # The first trade's premium as a fraction of the share price -
        premium_hist = _attempt(() -> _student(calls, lookup, :call_premium, ticker, _check_premium,
            plan.S0, K, Δt, plan.σ̂, config.gᵧ) / plan.S0);
        premium_iv = _attempt(() -> _student(calls, lookup, :call_premium, ticker, _check_premium,
            plan.S0, K, Δt, plan.call_iv, config.gᵧ) / plan.S0);

        # The holding benchmark: the same shares and opening cash, no calls -
        holding = _attempt(() -> _model_holding_rates(calls, lookup, ticker, S, Δt, config));

        # The fund, with the calls priced at each volatility -
        fund_hist = _attempt(() -> _model_fund_rates(calls, lookup, ticker, S, plan.call_moneyness, plan.σ̂,
            Δt, increment, config));
        fund_iv = _attempt(() -> _model_fund_rates(calls, lookup, ticker, S, plan.call_moneyness, plan.call_iv,
            Δt, increment, config));
        beats(f) = (f === missing || holding === missing) ? missing : mean(f.rates .> holding);
        loss(r) = r === missing ? missing : mean(r .< 0);
        rates(f) = f === missing ? missing : f.rates;
        borrows(f) = f === missing ? missing : mean(f.borrowed);

        # Promise versus outcome: the real roll's strike multiples, lengths, and dates, with simulated share prices -
        matched = _attempt(() -> _matched_rates(calls, lookup, roll, roll_prices(roll, config, index), config));
        differences[ticker] = matched === missing ? missing : matched.fund .- matched.holding;

        row = (ticker = ticker, group = roll.group, call_moneyness = plan.call_moneyness, σ̂ = plan.σ̂,
            call_iv = plan.call_iv, premium_hist = premium_hist, premium_iv = premium_iv,
            premium_market = plan.call_fraction,
            holding_mean = _mean(holding), holding_sd = holding === missing ? missing : std(holding),
            holding_loss = loss(holding),
            fund_hist_mean = _mean(rates(fund_hist)), fund_hist_loss = loss(rates(fund_hist)),
            fund_hist_beats = beats(fund_hist), fund_hist_borrows = borrows(fund_hist),
            fund_iv_mean = _mean(rates(fund_iv)), fund_iv_loss = loss(rates(fund_iv)),
            fund_iv_beats = beats(fund_iv), fund_iv_borrows = borrows(fund_iv),
            fund_iv_sd = fund_iv === missing ? missing : std(fund_iv.rates),
            matched_beats = matched === missing ? missing : mean(matched.fund .> matched.holding));

        # Advanced: the collar fund, both options priced at their implied volatilities -
        if advanced
            put_iv = _attempt(() -> _student(calls, lookup, :put_premium, ticker, _check_premium,
                plan.S0, plan.put_moneyness * plan.S0, Δt, plan.put_iv, config.gᵧ) / plan.S0);
            collar = _attempt(() -> _model_collar_rates(calls, lookup, ticker, S, plan, Δt, increment, config));
            row = merge(row, (put_moneyness = plan.put_moneyness, put_iv = plan.put_iv,
                put_premium_iv = put_iv, collar_mean = _mean(rates(collar)), collar_loss = loss(rates(collar)),
                collar_beats = beats(collar), collar_borrows = borrows(collar),
                collar_sd = collar === missing ? missing : std(collar.rates)));
        end
        push!(rows, row);

        # The strike-choice table: the same paths, every target strike priced at the call's implied volatility -
        for m in config.moneyness_grid
            fund = _attempt(() -> _model_fund_rates(calls, lookup, ticker, S, m, plan.call_iv, Δt, increment, config));
            push!(strike_rows, (ticker = ticker, moneyness = m,
                difference_mean = (fund === missing || holding === missing) ? missing : mean(fund.rates .- holding),
                beats = beats(fund), fund_loss = loss(rates(fund)), borrows = borrows(fund)));
        end
    end

    return (tickers = DataFrame(rows), strikes = DataFrame(strike_rows), differences = differences);
end

# --- Study 2: what happened ------------------------------------------------------------------

# One strategy's wealth ratios over a ticker's real roll, in time order. Each trade's month comes
# from `month_of(m, C)`, which returns `(ratio, cash)` for trade `m` and the cash `C` at its
# entry; between an expiration and a later entry the strategy holds its shares and its cash grows.
# Also counts the months that end with negative cash.
function _history_ratios(roll, config, month_of::Function)::NamedTuple
    N_S = config.N_S;
    C = _opening_cash(config, roll.months[1].S_start);
    ratios = Float64[];
    negative_months = 0;
    for (j, m) in enumerate(roll.months)
        if j > 1
            previous = roll.months[j-1];
            if m.gap_days > 0 || m.S_start != previous.S_end
                step = _gap_step(N_S, previous.S_end, m.S_start, exp(config.gᵧ * m.gap_days / PS5_CALENDAR_DAYS), C);
                push!(ratios, step.ratio); C = step.cash;
            end
        end
        month = month_of(m, C);
        push!(ratios, month.ratio); C = month.cash;
        negative_months += C < 0;
    end
    return (ratios = ratios, negative_months = negative_months);
end

"""
    evaluate_history(track, rolls, closes, config; lookup) -> DataFrame

Study 2. Replay each ticker's real monthly roll with a fund that holds N_S shares and a cash
account: on every trade it sells the calls at their mid price (and, for comparison, at their
bid), the premium goes into the cash, which earns the risk-free rate, and the calls are settled
at the close on the expiration date. Between an expiration and a later entry the fund holds its
shares and its cash grows. The holding benchmark holds the same shares and opening cash and
sells no calls.

# Returns
One row per ticker: `ticker, group, first_entry, last_expiration, T` (years), `months`,
`months_called` (trades whose close at expiration was above the call's strike),
`months_borrowed` (months that end with the fund's cash negative), `premium_market` (average
call mid price over the share price at entry), `fund_g`, `fund_bid_g`, `holding_g`,
`benchmark_g` (the market benchmark over the same dates), `cash_g` (the risk-free rate), and
`fund_beat` (`fund_g > holding_g`); on the Advanced track also `collar_g`, `months_floored`
(closes below the put's strike), `put_cost` (average put mid over the share price), and
`collar_beat`. Growth rates are in 1/yr, `missing` when a student function failed.
"""
function evaluate_history(track::String, rolls::Vector{NamedTuple}, closes::AbstractDict, config::NamedTuple,
    calls::StudentCalls; lookup::Function = name -> getfield(Main, name))::DataFrame

    rows = NamedTuple[];
    N_S = config.N_S;
    for roll in rolls
        ticker = roll.ticker;
        months = roll.months;
        𝒟(m) = exp(config.gᵧ * m.days / PS5_CALENDAR_DAYS);

        # The fund at the mid and at the bid, and the holding benchmark -
        fund = _attempt(() -> _history_ratios(roll, config, (m, C) -> _student(calls, lookup,
            :covered_call_month, ticker, _check_month, N_S, m.S_start, m.S_end, m.K_call, m.call_mid, 𝒟(m), C)));
        fund_bid = _attempt(() -> _history_ratios(roll, config, (m, C) -> _student(calls, lookup,
            :covered_call_month, ticker, _check_month, N_S, m.S_start, m.S_end, m.K_call, m.call_bid, 𝒟(m), C)));
        holding = _history_ratios(roll, config, (m, C) ->
            (ratio = (N_S * m.S_end + 𝒟(m) * C) / (N_S * m.S_start + C), cash = 𝒟(m) * C));
        rate(r) = r === missing ? missing :
            _attempt(() -> _student(calls, lookup, :growth_rate, ticker, _check_rate, r.ratios, roll.T));
        fund_g, fund_bid_g, holding_g = rate(fund), rate(fund_bid), rate(holding);

        benchmark_g = log(closes[roll.last_expiration] / closes[roll.first_entry]) / roll.T;
        row = (ticker = ticker, group = roll.group, first_entry = roll.first_entry,
            last_expiration = roll.last_expiration, T = roll.T, months = length(months),
            months_called = count(m.S_end > m.K_call for m in months),
            months_borrowed = fund === missing ? missing : fund.negative_months,
            premium_market = mean(m.call_mid / m.S_start for m in months),
            fund_g = fund_g, fund_bid_g = fund_bid_g, holding_g = holding_g, benchmark_g = benchmark_g,
            cash_g = config.gᵧ,
            fund_beat = (fund_g === missing || holding_g === missing) ? missing : fund_g > holding_g);

        if track == "advanced"
            collar = _attempt(() -> _history_ratios(roll, config, (m, C) -> _student(calls, lookup,
                :collar_month, ticker, _check_month, N_S, m.S_start, m.S_end, m.K_put, m.K_call,
                m.put_mid, m.call_mid, 𝒟(m), C)));
            collar_g = rate(collar);
            row = merge(row, (collar_g = collar_g, months_floored = count(m.S_end < m.K_put for m in months),
                put_cost = mean(m.put_mid / m.S_start for m in months),
                collar_beat = (collar_g === missing || holding_g === missing) ? missing : collar_g > holding_g));
        end
        push!(rows, row);
    end
    return DataFrame(rows);
end

# --- Summary tables --------------------------------------------------------------------------

"""
    summary_table(track, history) -> DataFrame

The headline of Study 2: one row per strategy, with the average, median, lowest, and highest
growth rate over the tickers (1/yr), and for the funds the number of tickers where the fund grew
faster than the holding benchmark (`beat_holding`). Rows: the covered call fund at mid prices, at
the bid, the collar fund (Advanced), and the benchmarks: holding the shares and cash, the market
benchmark, and cash.
"""
function summary_table(track::String, history::DataFrame, benchmark_ticker::AbstractString)::DataFrame
    entries = [("Fund (mid prices)", :fund_g, true), ("Fund (calls sold at the bid)", :fund_bid_g, true)];
    track == "advanced" && push!(entries, ("Collar fund (mid prices)", :collar_g, true));
    push!(entries, ("Holding: shares and cash, no calls", :holding_g, false));
    push!(entries, ("$(benchmark_ticker), price only", :benchmark_g, false));
    push!(entries, ("Cash (risk-free rate)", :cash_g, false));
    rows = NamedTuple[];
    for (label, column, is_fund) in entries
        values = _present(history[!, column]);
        complete = length(values) == nrow(history);
        holding_complete = !any(ismissing, history.holding_g);
        # The benchmarks are not compared with holding; a fund's count needs every growth rate -
        beat_count = !is_fund ? "—" : (complete && holding_complete) ?
            count(Float64.(history[!, column]) .> Float64.(history.holding_g)) : missing;
        push!(rows, (strategy = label, tickers = length(values),
            avg_g = complete ? _mean(values) : missing, median_g = complete ? _median(values) : missing,
            lowest_g = complete ? minimum(values) : missing, highest_g = complete ? maximum(values) : missing,
            beat_holding = beat_count));
    end
    return DataFrame(rows);
end

"""
    model_summary(track, model) -> DataFrame

Study 1 averaged over the tickers: one row per strategy and pricing volatility, with the average
first-trade premium (fraction of the share price), the average of each ticker's mean growth rate
(1/yr), and the average probabilities that the growth rate is negative, that the fund beats the
holding benchmark, and that the fund's cash ends a month negative.
"""
function model_summary(track::String, model::DataFrame)::DataFrame
    avg(c) = (v = model[!, c]; any(ismissing, v) ? missing : mean(Float64.(v)));
    rows = NamedTuple[
        (strategy = "Holding: shares and cash, no calls", premium = "—", mean_g = avg(:holding_mean),
            loss = avg(:holding_loss), beats = "—", borrows = "—"),
        (strategy = "Fund, calls at historical vol", premium = avg(:premium_hist),
            mean_g = avg(:fund_hist_mean), loss = avg(:fund_hist_loss), beats = avg(:fund_hist_beats),
            borrows = avg(:fund_hist_borrows)),
        (strategy = "Fund, calls at implied vol", premium = avg(:premium_iv),
            mean_g = avg(:fund_iv_mean), loss = avg(:fund_iv_loss), beats = avg(:fund_iv_beats),
            borrows = avg(:fund_iv_borrows))];
    if track == "advanced"
        push!(rows, (strategy = "Collar fund, at implied vol",
            premium = (ismissing(avg(:premium_iv)) || ismissing(avg(:put_premium_iv))) ? missing :
                avg(:premium_iv) - avg(:put_premium_iv),
            mean_g = avg(:collar_mean), loss = avg(:collar_loss), beats = avg(:collar_beats),
            borrows = avg(:collar_borrows)));
    end
    return DataFrame(rows);
end

"""
    strike_summary(strikes) -> DataFrame

The strike-choice table averaged over the tickers: one row per target strike multiple, with the
average mean of the fund-minus-holding growth rate, and the average probabilities that the fund
beats the holding benchmark, that it loses money, and that its cash ends a month negative.
"""
function strike_summary(strikes::DataFrame)::DataFrame
    rows = NamedTuple[];
    for m in sort(unique(strikes.moneyness))
        d = strikes[strikes.moneyness .== m, :];
        avg(c) = any(ismissing, d[!, c]) ? missing : mean(Float64.(d[!, c]));
        push!(rows, (moneyness = m, difference_mean = avg(:difference_mean),
            beats = avg(:beats), fund_loss = avg(:fund_loss), borrows = avg(:borrows)));
    end
    return DataFrame(rows);
end

"""
    promise_table(model, history, differences) -> DataFrame

Promise versus outcome, one row per ticker: the model's probability that the fund beats the
holding benchmark on the real roll's strike multiples, implied volatilities, and dates
(`model_beats`), whether it did (`fund_beat`), the real fund-minus-holding growth rate
(`difference`), and where that difference falls among the simulated ones (`percentile`, the
fraction of simulated differences at or below it).
"""
function promise_table(model::DataFrame, history::DataFrame, differences::AbstractDict)::DataFrame
    rows = NamedTuple[];
    for (m, h) in zip(eachrow(model), eachrow(history))
        difference = (h.fund_g === missing || h.holding_g === missing) ? missing : h.fund_g - h.holding_g;
        simulated = differences[m.ticker];
        percentile = (difference === missing || simulated === missing) ? missing : mean(simulated .<= difference);
        push!(rows, (ticker = m.ticker, model_beats = m.matched_beats, fund_beat = h.fund_beat,
            difference = difference, percentile = percentile, holding_g = h.holding_g,
            months_called = h.months_called));
    end
    return DataFrame(rows);
end

# --- Writing the report ----------------------------------------------------------------------

"""
    write_table_csv(path, table) -> Nothing

Write a table as CSV at full Float64 precision, every cell quoted. Missing values are written
as UNAVAILABLE.
"""
function write_table_csv(path::AbstractString, table::DataFrame)::Nothing
    cell(x) = "\"" * replace(ismissing(x) ? "UNAVAILABLE" : string(x), '"' => "\"\"") * "\"";
    open(path, "w") do io
        println(io, join(names(table), ','));
        for row in eachrow(table)
            println(io, join([cell(row[c]) for c in names(table)], ','));
        end
    end
    return nothing;
end

# Display formats.
_shown(x::Real, digits::Int) = (v = round(x; digits = digits); v == 0 ? zero(v) : v);
_text(x) = ismissing(x) ? "UNAVAILABLE" : string(x);
_count(x) = ismissing(x) ? "UNAVAILABLE" : string(x);
_rate(x) = ismissing(x) ? "UNAVAILABLE" : @sprintf("%.1f%%", _shown(100 * x, 1));
_premium(x) = ismissing(x) ? "UNAVAILABLE" : @sprintf("%.2f%%", _shown(100 * x, 2));
_g(x) = ismissing(x) ? "UNAVAILABLE" : @sprintf("%+.3f", _shown(x, 3));
_multiple(x) = ismissing(x) ? "UNAVAILABLE" : @sprintf("%.3f", x);
_vol(x) = ismissing(x) ? "UNAVAILABLE" : @sprintf("%.3f", x);
_yesno(x) = ismissing(x) ? "UNAVAILABLE" : (x ? "yes" : "no");
_blank(x) = ismissing(x) ? "—" : x;

# A displayed table: headers, formatted rows, and the right-aligned (numeric) columns.
function _display(table::AbstractDataFrame, spec)
    headers = [h for (h, _, _) in spec];
    rows = [[f(row[c]) for (_, c, f) in spec] for row in eachrow(table)];
    right = [j for (j, (_, _, f)) in enumerate(spec) if f !== _text];
    return (headers = headers, rows = rows, right = right);
end

# Write one Markdown table, with numeric columns aligned right.
function _markdown_table(io, shown)
    println(io, "| ", join(shown.headers, " | "), " |");
    println(io, "|", join([j in shown.right ? " --: " : " :-- " for j in eachindex(shown.headers)], "|"), "|");
    for row in shown.rows
        println(io, "| ", join(row, " | "), " |");
    end
    isempty(shown.rows) && println(io, "\nNo rows. See the calculations that could not run.");
    println(io);
    return nothing;
end

# A text entry, such as the dash of a value that does not apply, is shown as it is.
_keep(f) = x -> x isa AbstractString ? x : f(x);

const _SUMMARY_COLUMNS = [("Strategy", :strategy, _text), ("Tickers", :tickers, _count),
    ("Avg growth rate (1/yr)", :avg_g, _g), ("Median", :median_g, _g), ("Lowest", :lowest_g, _g),
    ("Highest", :highest_g, _g), ("Tickers that beat holding", :beat_holding, _count)];
const _MODEL_SUMMARY_COLUMNS = [("Strategy", :strategy, _text), ("Avg premium (% of share price)", :premium, _keep(_premium)),
    ("Avg mean growth rate (1/yr)", :mean_g, _g), ("Avg P(growth rate < 0)", :loss, _rate),
    ("Avg P(beats holding)", :beats, _keep(_rate)), ("Avg P(cash goes negative)", :borrows, _keep(_rate))];
const _PREMIUM_COLUMNS = [("Ticker", :ticker, _text), ("Call strike / share price", :call_moneyness, _multiple),
    ("Historical vol", :σ̂, _vol), ("Call implied vol", :call_iv, _vol),
    ("Model premium at historical vol", :premium_hist, _premium), ("Model premium at implied vol", :premium_iv, _premium),
    ("Market premium (mid)", :premium_market, _premium)];
const _STRIKE_COLUMNS = [("Target strike / share price", :moneyness, _multiple),
    ("Avg mean of fund minus holding growth rate (1/yr)", :difference_mean, _g),
    ("Avg P(fund beats holding)", :beats, _rate), ("Avg P(fund growth rate < 0)", :fund_loss, _rate),
    ("Avg P(cash goes negative)", :borrows, _rate)];
const _HISTORY_COLUMNS = [("Ticker", :ticker, _text), ("Months", :months, _count), ("Months called away", :months_called, _count),
    ("Months ending with negative cash", :months_borrowed, _count),
    ("Avg premium (% of share price)", :premium_market, _premium), ("Fund growth rate", :fund_g, _g),
    ("Holding growth rate", :holding_g, _g), ("Fund beat holding", :fund_beat, _yesno)];
const _PROMISE_COLUMNS = [("Ticker", :ticker, _text), ("Model P(fund beats holding)", :model_beats, _rate),
    ("Fund beat holding", :fund_beat, _yesno), ("Fund minus holding growth rate (1/yr)", :difference, _g),
    ("Model percentile of what happened", :percentile, _rate)];
const _COLLAR_COLUMNS = [("Ticker", :ticker, _text), ("Months floored by the put", :months_floored, _count),
    ("Months called away", :months_called, _count), ("Avg put cost (% of share price)", :put_cost, _premium),
    ("Collar fund growth rate", :collar_g, _g), ("Covered call fund growth rate", :fund_g, _g),
    ("Holding growth rate", :holding_g, _g)];

# The average of a premium column over the tickers, for the row under the premium table.
function _premium_average_row(model::DataFrame)
    avg(c) = any(ismissing, model[!, c]) ? missing : mean(Float64.(model[!, c]));
    return DataFrame([(ticker = "**Average**", call_moneyness = mean(model.call_moneyness), σ̂ = mean(model.σ̂),
        call_iv = mean(model.call_iv), premium_hist = avg(:premium_hist), premium_iv = avg(:premium_iv),
        premium_market = mean(model.premium_market))]);
end

# The expected number of tickers where the fund beats holding, and what happened.
function _promise_sentence(promise::DataFrame)::String
    if any(ismissing, promise.model_beats) || any(ismissing, promise.fund_beat)
        return "The expected and actual counts are UNAVAILABLE until every function works.";
    end
    expected = sum(Float64.(promise.model_beats));
    actual = count(Bool.(promise.fund_beat));
    return @sprintf("The model expected the fund to beat holding the shares on %.1f of the %d tickers (the sum of the probabilities); it did on %d.",
        expected, nrow(promise), actual);
end

function _run_description(track::AbstractString, rolls, config, config_name::AbstractString)
    trades = sum(length(r.months) for r in rolls);
    first_date = minimum(r.first_entry for r in rolls);
    last_date = maximum(r.last_expiration for r in rolls);
    paths = replace(string(config.number_of_paths), r"(?<=\d)(?=(\d{3})+$)" => ",");
    text = "$(titlecase(track)) track. $(length(rolls)) tickers, $(trades) monthly calls in all, " *
        "from $(first_date) to $(last_date). Each ticker's fund holds $(config.N_S) shares and a cash account, " *
        "and every month sells $(config.number_of_contracts) call contracts of $(config.shares_per_contract) shares; " *
        "it opens with cash equal to $(@sprintf("%.0f", 100 * config.cash_reserve))% of the value of its shares " *
        "and borrows at the risk-free rate when the cash runs out.";
    settings = "Settings ($(config_name)): risk-free rate $(@sprintf("%.4f", config.gᵧ)) per year " *
        "(continuously compounded, from a $(@sprintf("%.2f", 100 * config.risk_free_rate))% 13-week bill yield), " *
        "$(paths) simulated paths per ticker, seed $(config.seed), 60-step binomial trees, " *
        "market benchmark $(config.benchmark_ticker).";
    return (text = text, settings = settings);
end

function _report_markdown(title, track, description, result)::String
    io = IOBuffer();
    t = result.tables;
    println(io, "# ", title, "\n");
    println(io, description.text, "\n");
    println(io, description.settings, "\n");
    isempty(result.issues) || println(io, "Some calculations could not run. They show UNAVAILABLE; ",
        "the last section says why.\n");

    println(io, "## Study 1: What does the model promise?\n");
    println(io, "For each ticker, the model simulates seven months of share prices with geometric Brownian motion, ",
        "using the drift and volatility from the year before the first entry date. Every month, which lasts as long as ",
        "the first trade, the fund sells calls at the smallest strike at or above the first trade's strike multiple ",
        "times the share price on the ticker's listed-strike grid (one spacing per ticker, an approximation of the real ",
        "listed strikes), and prices them on the binomial tree. ",
        "The premiums go into the fund's cash, which earns the risk-free rate; when a call is exercised, the fund buys ",
        "new shares from its cash, borrowing at the risk-free rate when the cash runs out. Holding: the same shares and ",
        "opening cash, with no calls. Growth rates are in 1/yr and use prices only: the fund and holding both omit dividends.\n");
    println(io, "### Premiums: model and market\n");
    println(io, "Each premium is a percentage of the share price, for the first trade of each ticker and its time ",
        "to expiration. The model prices the call on the binomial tree at the historical volatility or at the call's ",
        "implied volatility; the market premium is the call's mid price.\n");
    _markdown_table(io, _display(vcat(t.model, _premium_average_row(t.model); cols = :union), _PREMIUM_COLUMNS));
    println(io, "### The fund and holding the shares in the model\n");
    println(io, "Each value is averaged over the tickers. For each ticker the model gives a mean growth rate and the ",
        "probabilities over its simulated paths.\n");
    _markdown_table(io, _display(t.model_summary, _MODEL_SUMMARY_COLUMNS));
    println(io, "Fund: the covered call fund, with its calls priced at the historical volatility or at the call's ",
        "implied volatility. ", track == "advanced" ? "Collar fund: its premium is the call's premium minus the put's. " : "",
        "P(beats holding): the probability that the fund's growth rate is above that of holding on the same path. ",
        "P(cash goes negative): the probability that the fund's cash ends at least one month negative, so it borrowed.\n");
    println(io, "### Strike choice in the model\n");
    println(io, "The same simulated paths, with the fund selling calls at other target strikes (each month, the smallest ",
        "listed strike at or above the target times the share price), all priced at each ticker's call implied volatility ",
        "(the model ignores how implied volatility changes with the strike). If the fund owes more than its shares are ",
        "worth on a simulated path, the fund is wiped out: the path stops and counts as a 99.9% loss of the fund's wealth.\n");
    _markdown_table(io, _display(t.strike_summary, _STRIKE_COLUMNS));

    println(io, "## Study 2: What happened?\n");
    println(io, "Each ticker's fund replays its real monthly calls: it sells the calls at their mid price, the premium ",
        "goes into its cash at the risk-free rate, and the calls settle at the close on the expiration date, with no early ",
        "exercise. Between an expiration and a later entry, the fund holds its shares and cash. Holding: the same shares ",
        "and opening cash, with no calls. Growth rates are over each ticker's own dates, about seven months, in 1/yr. They ",
        "use closing prices only: the fund, holding, and SPY all omit dividends.\n");
    println(io, "### Growth rates and benchmarks\n");
    _markdown_table(io, _display(t.summary, _SUMMARY_COLUMNS));
    println(io, "Calls sold at the bid: the same fund, receiving the bid instead of the mid; the gap is a rough cost ",
        "of trading if the quoted spreads were real. The benchmarks are over each ticker's own dates.\n");
    println(io, "### Each ticker\n");
    _markdown_table(io, _display(t.history, _HISTORY_COLUMNS));
    println(io, "### Promise versus outcome\n");
    println(io, "Here the model follows each ticker's real roll: every trade keeps its real strike as a multiple of the ",
        "share price at entry, its real length, its call's implied volatility, and the days between trades. The share ",
        "prices are simulated, with the drift and volatility from the year before the first entry date; each simulated ",
        "call has the smallest listed strike at or above that multiple of the simulated price, and its premium is the ",
        "binomial tree's at the call's implied volatility, not the market's mid price.\n");
    println(io, _promise_sentence(t.promise), "\n");
    _markdown_table(io, _display(t.promise, _PROMISE_COLUMNS));
    println(io, "Model percentile of what happened: the share of the model's simulated fund-minus-holding growth rates ",
        "at or below the real one. Near 0% or 100% means what happened was rare under the model.\n");

    if track == "advanced"
        println(io, "## Advanced: the collar fund\n");
        println(io, "The collar fund also buys one-month puts each month (the trade's protective put, near 0.10 delta), ",
            "paid for in part by the calls, with the same cash account. Months floored: closes below the put's strike.\n");
        _markdown_table(io, _display(t.history, _COLLAR_COLUMNS));
    end

    if !isempty(result.issues)
        println(io, "## Calculations that could not run\n");
        for issue in result.issues
            println(io, "- ", replace(issue, '\n' => " "));
        end
        println(io);
    end
    return String(take!(io));
end

function _print_terminal_report(title, description, result, report_path)
    t = result.tables;
    print_terminal_section(title; major = true);
    print_terminal_text(description.text);
    print_terminal_section("Study 1: the model, averaged over the tickers");
    shown = _display(t.model_summary, [("Strategy", :strategy, _text), ("Avg mean g", :mean_g, _g),
        ("P(g < 0)", :loss, _rate), ("P(beats holding)", :beats, _keep(_rate))]);
    print_terminal_table(shown.headers, shown.rows; right_columns = shown.right);
    print_terminal_section("Study 2: what happened (growth rates in 1/yr)");
    shown = _display(t.summary, [("Strategy", :strategy, _text), ("Avg g", :avg_g, _g),
        ("Median", :median_g, _g), ("Beat holding", :beat_holding, _count)]);
    print_terminal_table(shown.headers, shown.rows; right_columns = shown.right);
    println();
    print_terminal_text(_promise_sentence(t.promise));
    if !isempty(result.issues)
        print_terminal_section("Calculations that could not run");
        for issue in result.issues
            print_terminal_text(issue; prefix = "- ", continuation = "  ");
        end
    end
    println();
    print_terminal_text("Full report, with the premiums, the strike choice, each ticker, and the promise " *
        "versus the outcome: $(report_path)");
    return nothing;
end

"""
    benchmark_closes(table, ticker, rolls) -> Dict{Date,Float64}

Check the daily closes of the market benchmark and return them by date. Throws an
`ArgumentError` when the closes are for another ticker or a roll's first entry or last
expiration date has no positive close.
"""
function benchmark_closes(table::DataFrame, ticker::AbstractString, rolls)::Dict{Date,Float64}
    issubset(["ticker", "date", "close"], names(table)) ||
        throw(ArgumentError("The benchmark closes must have the columns ticker, date, and close."));
    sort(unique(string.(table.ticker))) == [ticker] ||
        throw(ArgumentError("The benchmark closes are not for benchmark_ticker $(ticker)."));
    closes = Dict{Date,Float64}(d => Float64(c) for (d, c) in zip(table.date, table.close)
        if d isa Date && c isa Real && isfinite(c) && c > 0);
    for r in rolls, d in (r.first_entry, r.last_expiration)
        haskey(closes, d) || throw(ArgumentError("The benchmark closes have no $(ticker) close on $(d)."));
    end
    return closes;
end

"""
    print_fund_report(track, root; output_directory, config_path, title, report_name) -> NamedTuple

Run the selected student functions on the model (Study 1) and on the real rolls (Study 2), print
the headline tables, and write `Report.md` (or `report_name`) and the CSV tables `model.csv`,
`strikes.csv`, `history.csv`, `summary.csv`, and `promise.csv` to `output_directory` (relative
to `root` unless absolute). Unfinished student functions show UNAVAILABLE rather than stopping
the report.

# Returns
`(tables, issues, report, seconds)`.
"""
function print_fund_report(track::AbstractString, root::AbstractString;
    output_directory::AbstractString = "results", config_path::AbstractString = "config/defaults.toml",
    title::AbstractString = "PS5 report", report_name::AbstractString = "Report.md",
    lookup::Function = name -> getfield(Main, name))::NamedTuple

    started = time();
    track = lowercase(String(track));
    track in ("standard", "advanced") || throw(ArgumentError("The track must be \"standard\" or \"advanced\"."));
    output_directory = isabspath(output_directory) ? output_directory : joinpath(root, output_directory);
    config = load_config(joinpath(root, config_path));
    trades = load_trade_table(joinpath(root, "data", "trades.csv"));
    parameters = CSV.read(joinpath(root, "data", "parameters.csv"), DataFrame);
    increments = load_strike_increments(joinpath(root, "data", "strike_increments.csv"), unique(trades.ticker));
    rolls = ticker_rolls(trades, parameters, increments);
    closes = benchmark_closes(CSV.read(joinpath(root, "data", "benchmark.csv"), DataFrame; stringtype = String),
        config.benchmark_ticker, rolls);

    calls = StudentCalls();
    model = evaluate_model(track, rolls, config, calls; lookup = lookup);
    history = evaluate_history(track, rolls, closes, config, calls; lookup = lookup);
    tables = (model = model.tickers, model_summary = model_summary(track, model.tickers),
        strikes = model.strikes, strike_summary = strike_summary(model.strikes), history = history,
        summary = summary_table(track, history, config.benchmark_ticker),
        promise = promise_table(model.tickers, history, model.differences));
    result = (tables = tables, issues = _call_issues(calls));

    mkpath(output_directory);
    for (name, table) in (("model", tables.model), ("strikes", tables.strikes), ("history", tables.history),
            ("summary", tables.summary), ("promise", tables.promise))
        write_table_csv(joinpath(output_directory, name * ".csv"), table);
    end
    description = _run_description(track, rolls, config, config_path);
    report_path = joinpath(output_directory, report_name);
    write(report_path, _report_markdown(title, track, description, result));
    shown_path = startswith(abspath(report_path), abspath(root)) ? relpath(report_path, root) : report_path;
    _print_terminal_report(title, description, result, shown_path);
    return (tables = tables, issues = result.issues, report = report_path, seconds = time() - started);
end
