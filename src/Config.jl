# PS5 settings: read a TOML settings file and check every value.
using TOML, SHA

"""
    config_setting(settings::Dict, key::String, T::Type)

Read one setting from a parsed TOML file and convert it to type `T`.

### Arguments

- `settings`: The parsed TOML file, from `TOML.parsefile`.
- `key`: The name of the setting.
- `T`: The type the setting must have, such as `Float64`, `Int`, or `String`.

### Returns

- The setting converted to `T`. Throws an `ArgumentError` when the setting is
  missing or cannot be converted. An integer setting must be written as a whole
  number (`60`, not `60.0`).
"""
function config_setting(settings::Dict, key::String, T::Type)

    # Is the setting in the file?
    if !haskey(settings, key)
        throw(ArgumentError("Setting '$key' is missing from the config file."));
    end
    value = settings[key];

    # Integer settings must be written as whole numbers -
    if T <: Integer && !(value isa Integer)
        throw(ArgumentError("Setting '$key' must be of type $T."));
    end

    # Convert the value to T -
    try
        return T(value);
    catch
        throw(ArgumentError("Setting '$key' must be of type $T."));
    end
end

"""
    check_setting(ok::Bool, message::String)

Throw an `ArgumentError` with `message` when a setting fails a check.
"""
function check_setting(ok::Bool, message::String)
    if !ok
        throw(ArgumentError(message));
    end
    return nothing;
end

"""
    load_config(path::AbstractString) -> NamedTuple

Read a TOML settings file and check every value.

### Arguments

- `path`: Location of the settings file, such as `config/defaults.toml`.

### Returns

- A `NamedTuple` with the fields `risk_free_rate`, `bill_term`, `gᵧ` (the
  continuously compounded risk-free rate, `log(1 + risk_free_rate·bill_term)/bill_term`,
  in 1/yr), `number_of_paths`, `seed`, `moneyness_grid`, `benchmark_ticker`,
  `shares_per_contract`, `number_of_contracts`, `cash_reserve`, `zero_wealth_ratio`, and `N_S`, the
  shares the fund holds (`shares_per_contract·number_of_contracts`). Throws an `ArgumentError` with a one-sentence message when a
  setting is missing or invalid.
"""
function load_config(path::AbstractString)::NamedTuple

    # Read the file -
    settings = nothing;
    try
        settings = TOML.parsefile(path);
    catch
        throw(ArgumentError("The config file could not be read as TOML."));
    end

    # Read each setting with its type -
    risk_free_rate = config_setting(settings, "risk_free_rate", Float64);
    bill_term = config_setting(settings, "bill_term", Float64);
    number_of_paths = config_setting(settings, "number_of_paths", Int);
    seed = config_setting(settings, "seed", Int);
    benchmark_ticker = config_setting(settings, "benchmark_ticker", String);
    shares_per_contract = config_setting(settings, "shares_per_contract", Int);
    number_of_contracts = config_setting(settings, "number_of_contracts", Int);
    cash_reserve = config_setting(settings, "cash_reserve", Float64);
    zero_wealth_ratio = config_setting(settings, "zero_wealth_ratio", Float64);

    # The moneyness grid is a list, so each entry is read and checked on its own -
    if !haskey(settings, "moneyness_grid") || !(settings["moneyness_grid"] isa AbstractVector)
        throw(ArgumentError("Setting 'moneyness_grid' must be a list of numbers."));
    end
    moneyness_grid = Float64[];
    for value in settings["moneyness_grid"]
        check_setting(value isa Real, "Setting 'moneyness_grid' must be a list of numbers.");
        push!(moneyness_grid, Float64(value));
    end

    # Check that each value makes sense -
    check_setting(risk_free_rate >= 0, "The risk_free_rate must not be negative.");
    check_setting(bill_term > 0, "The bill_term must be positive.");
    check_setting(number_of_paths >= 1000, "The number_of_paths must be at least 1000.");
    check_setting(!isempty(moneyness_grid) && all(m -> 0.8 <= m <= 1.5, moneyness_grid),
        "Every moneyness in moneyness_grid must be from 0.8 to 1.5.");
    check_setting(!isempty(benchmark_ticker), "The benchmark_ticker must not be empty.");
    check_setting(shares_per_contract >= 1, "The shares_per_contract must be at least 1.");
    check_setting(number_of_contracts >= 1, "The number_of_contracts must be at least 1.");
    check_setting(0 <= cash_reserve <= 1, "The cash_reserve must be from 0 to 1.");
    check_setting(0 < zero_wealth_ratio < 1, "The zero_wealth_ratio must be between 0 and 1.");

    # The continuously compounded risk-free rate, as in the course examples (1/yr) -
    gᵧ = log(1 + risk_free_rate * bill_term) / bill_term;

    # The settings, with the risk-free rate and the fund's number of shares -
    return (risk_free_rate = risk_free_rate, bill_term = bill_term, gᵧ = gᵧ,
        number_of_paths = number_of_paths, seed = seed,
        moneyness_grid = moneyness_grid, benchmark_ticker = benchmark_ticker,
        shares_per_contract = shares_per_contract, number_of_contracts = number_of_contracts,
        cash_reserve = cash_reserve, zero_wealth_ratio = zero_wealth_ratio,
        N_S = shares_per_contract * number_of_contracts);
end

"""
    config_hash(path::AbstractString) -> String

Compute the SHA-256 hash of a settings file, so a run records exactly which settings it used.

### Returns

- The SHA-256 hash of the file as a 64-character hex string. Windows line
  endings are changed to `\\n` first, so a copy saved on Windows has the same
  hash.
"""
function config_hash(path::AbstractString)::String

    # Use the same line endings on every operating system, then hash the text -
    text = replace(read(path, String), "\r\n" => "\n");
    return bytes2hex(sha256(text));
end
