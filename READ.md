# XAUDesk — Synthetic Gold (XAUx) on Polygon

**Live dApp:** https://commoditydex.netlify.app/  
**Primary Contract (Polygon):** `0xa930e4899cf88e29A3ae923147cA27E7ab04c6B0`  
**License:** MIT  
**Status:** MVP (experimental, not audited)

XAUDesk lets users **mint and burn a synthetic gold token (XAUx)** using **USDC** as collateral. Pricing is fetched from the **Chainlink XAU/USD oracle** on Polygon. One XAUx ≈ **1 troy ounce** (18 decimals).

---

## Features
- 🔗 Chainlink XAU/USD oracle (8 decimals) with freshness checks (`maxStaleTime`)
- 💱 Buy/Sell at oracle price (`buy`, `sell`)
- 🧮 Correct decimals: token 18, feed 8, USDC 6 → `SCALER = 1e20`
- 🛡 Minimal reentrancy guard

## Addresses
| Network | Contract         | Address |
|--------|-------------------|--------|
| Polygon | XAUxDeskPolygon  | `0xa930e4899cf88e29A3ae923147cA27E7ab04c6B0` |

**Hardcoded dependencies in contract**
- USDC (Polygon, 6 dec): `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359`
- Chainlink XAU/USD (8 dec): `0x0C466540B2ee1a31b441671eac0ca886e051E410`

## Repo layout
contracts/ # XAUxDeskPolygon.sol
addresses/ # per-network address maps
docs/ # screenshots/diagrams (optional)
abi/ # exported ABIs (optional)

