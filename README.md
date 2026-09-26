# bybit-1m-data

1-minute OHLCV candles for Bybit **USDT linear perpetual** contracts, collected from Bybit's public market-data
(kline) API and repackaged as Parquet. Provided **as is**, without any warranty of completeness or correctness;
not investment advice. Bybit is the original source of the data; this repository is not affiliated with Bybit.

## Contents

| file | what |
|---|---|
| `universe.json` | list of contracts, why each is included, first/last bar |
| `qc.json` | quality report per contract: gaps, OHLC consistency, row counts |
| `manifest.json` | release assets → contracts, size, sha256 |
| `fetch_data.sh` | downloads the release assets (no login needed) and unpacks into `data/` |

The data itself is **not** in git history; it is attached to GitHub release **`v1`** as zip files
(parquet inside, 14–15 contracts per zip).

```bash
./fetch_data.sh                # everything  (2.58 GB)
./fetch_data.sh top_part01     # only assets whose name contains the given substring(s)
```
Requires `bash`, `curl`, `python3`, `sha256sum`. Result:
```
data/ohlcv/<SYMBOL>.parquet
data/funding/<SYMBOL>.parquet   # only for contracts that have funding history, see below
```

## Coverage

- 100 contracts (`source: "top100"`): the first 100 coins by **current** market capitalization
  (CoinGecko snapshot 2026-09-25) that have a Bybit USDT perpetual with ≥ 9 months of history in this set;
  stablecoins, tokenized gold and non-crypto (stock/ETF/commodity) contracts are excluded.
  Note: selecting by *today's* market cap is an ex-post selection.
- 185 contracts (`source: "delisted"`): perpetuals that have since been delisted from Bybit, with ≥ 9 months of history in this set.
- Dates: from 2024-01-01 (UTC) up to the cutoff below. Many contracts start later (listing date), see `universe.json`.
- **Cutoff: the data ends before 2026-06-01 00:00:00 UTC** (`ts < 1780272000000`). No bars at or after this time are included.

## OHLCV format (`data/ohlcv/<SYMBOL>.parquet`, zstd)

| column | type | meaning |
|---|---|---|
| `ts` | int64 | bar **open** time, milliseconds since Unix epoch, **UTC** |
| `open`, `high`, `low`, `close` | float32 | contract price in USDT |
| `volume` | float32 | volume in contract base units |

- Symbols with a `1000` / `10000` / `1000000` prefix (or `SHIB1000`) quote the price of 1000 / 10000 / 1000000 coins;
  the multiplier is in `universe.json` (`price_multiplier`).
- Missing minutes are **not filled** (no synthetic bars). A missing minute usually means no trades or a collection gap.
  All gaps longer than 5 minutes are listed in `qc.json`.
- Rows violating `low ≤ min(open, close) ≤ max(open, close) ≤ high` are **kept unchanged** and counted in `qc.json`.

```python
import pandas as pd
df = pd.read_parquet("data/ohlcv/BTCUSDT.parquet")
df["time"] = pd.to_datetime(df["ts"], unit="ms", utc=True)
```

## Funding (`data/funding/<SYMBOL>.parquet`)

| column | type | meaning |
|---|---|---|
| `ts` | int64 | funding settlement time, ms since epoch, UTC |
| `rate` | float64 | funding rate for that interval (as published by Bybit; interval may be 8h, 4h, 2h or 1h) |

Funding history is included for the `top100` contracts only (same cutoff). **For delisted contracts there is no funding history**
in this set (`has_funding: false` in `universe.json`).

## QC summary

- 285 contracts, 232,292,297 rows total.
- Gaps > 5 min: 1017559 in total (per contract in `qc.json`).
- Rows with OHLC inconsistencies (kept as is): 0.
- Every file: `max(ts) < 1780272000000` (2026-06-01 00:00 UTC).

## License / disclaimer

Data is redistributed as is for research purposes. Original market data © Bybit. Scripts in this repository: MIT.
No guarantee of accuracy, completeness or fitness for any purpose.
