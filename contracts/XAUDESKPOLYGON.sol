// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
/* -------- Minimal interfaces (no external imports) -------- */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function transfer(address to, uint256 amt) external returns (bool);
    function allowance(address o, address s) external view returns (uint256);
    function approve(address s, uint256 amt) external returns (bool);
    function transferFrom(address f, address t, uint256 amt) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
}
/* ------------------- Simple Reentrancy Guard ------------------- */
abstract contract ReentrancyGuard {
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "Reentrancy");
        _locked = 2;
        _;
        _locked = 1;
    }
}
/* ----------------------- Minimal ERC20 ------------------------- */
contract ERC20Simple {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

name = n;
        symbol = s;
    }
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function _mint(address to, uint256 amt) internal {
        totalSupply += amt;
        balanceOf[to] += amt;
        emit Transfer(address(0), to, amt);
    }
    function _burn(address from, uint256 amt) internal {
        require(balanceOf[from] >= amt, "Insufficient balance");
        balanceOf[from] -= amt;
        totalSupply -= amt;
        emit Transfer(from, address(0), amt);
    }
function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        emit Approval(msg.sender, spender, amt);
        return true;
    }
    function transfer(address to, uint256 amt) external returns (bool) {
        require(balanceOf[msg.sender] >= amt, "Insufficient balance");
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        emit Transfer(msg.sender, to, amt);
        return true;
    }
    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        require(a >= amt, "Insufficient allowance");
        allowance[from][msg.sender] = a - amt;
        require(balanceOf[from] >= amt, "Insufficient balance");
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
        emit Transfer(from, to, amt);
        return true;
    }
}
/* ------------------ XAUx on Polygon (Mainnet) ------------------ */
/**
 * @title XAUxDeskPolygon
 * @notice Mint/burn XAUx (1 token = 1 troy ounce, 18 decimals) using USDC as collateral
 *         and Chainlink XAU/USD (8 decimals) for pricing on Polygon Mainnet.
 *         Math: 18-token, 8-feed, 6-USDC => SCALER = 1e20.
 */
 contract XAUxDeskPolygon is ERC20Simple, ReentrancyGuard {
    // ✅ Polygon Mainnet addresses (checksummed)
    address private constant USDC_ADDRESS = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359; // native USDC (6 dec)
    address private constant XAU_USD_FEED = 0x0C466540B2ee1a31b441671eac0ca886e051E410; // Chainlink XAU/USD (8 dec)
    IERC20 public immutable USDC;
    AggregatorV3Interface public immutable PRICE_FEED;
    address public immutable owner;
    // Price freshness (default 1 hour)
    uint256 public maxStaleTime = 1 hours;
    // 1e18 * 1e8 / 1e6 = 1e20
    uint256 private constant SCALER = 1e20;

event Bought(address indexed buyer, uint256 usdcIn, uint256 tokensOut, uint256 price);
    event Sold(address indexed seller, uint256 tokensIn, uint256 usdcOut, uint256 price);
    event LiquidityWithdrawn(address indexed to, uint256 usdcAmount);
    event MaxStaleTimeUpdated(uint256 maxStaleTime);

USDC = IERC20(USDC_ADDRESS);
        PRICE_FEED = AggregatorV3Interface(XAU_USD_FEED);
        owner = msg.sender;
// Sanity checks protect against wrong networks/addresses
        require(USDC.decimals() == 6, "USDC must be 6 decimals");
        require(PRICE_FEED.decimals() == 8, "Feed must be 8 decimals");
        }

    /* -------------------------- Admin -------------------------- */
    function setMaxStaleTime(uint256 seconds_) external {
        require(msg.sender == owner, "Only owner");
        require(seconds_ >= 60 && seconds_ <= 24 hours, "Out of range");
        maxStaleTime = seconds_;
        emit MaxStaleTimeUpdated(seconds_);
    }
    function withdrawUSDC(address to, uint256 amount) external nonReentrant {
        require(msg.sender == owner, "Only owner");
        require(USDC.transfer(to, amount), "USDC transfer failed");
        emit LiquidityWithdrawn(to, amount);
    }
    /* ------------------------- Pricing ------------------------- */
    function _getFreshPrice() internal view returns (uint256 price, uint256 updatedAt) {
        (, int256 answer,, uint256 _updatedAt,) = PRICE_FEED.latestRoundData();
        require(answer > 0, "Bad price");
        require(block.timestamp - _updatedAt <= maxStaleTime, "Stale price");
        return (uint256(answer), _updatedAt); // USD * 1e8 per ounce
    }
    /* -------------------------- Quotes -------------------------- */
    function quoteBuy(uint256 usdcAmount)
        external view
        returns (uint256 tokensOut, uint256 price, uint256 updatedAt)
    {
    (price, updatedAt) = _getFreshPrice();
        tokensOut = (usdcAmount * SCALER) / price;
    }
function quoteSell(uint256 tokenAmount)
        external view
        returns (uint256 usdcOut, uint256 price, uint256 updatedAt)
    {
    (price, updatedAt) = _getFreshPrice();
        usdcOut = (tokenAmount * price) / SCALER;
    }
    /* ------------------------ Buy / Sell ------------------------ */
    function buy(uint256 usdcAmount) external nonReentrant {
        require(usdcAmount > 0, "Zero amount");
        (uint256 price, ) = _getFreshPrice();
require(USDC.transferFrom(msg.sender, address(this), usdcAmount), "USDC transferFrom failed");
uint256 tokensOut = (usdcAmount * SCALER) / price;
        require(tokensOut > 0, "Too little");
        _mint(msg.sender, tokensOut);
        emit Bought(msg.sender, usdcAmount, tokensOut, price);
    }
    function sell(uint256 tokenAmount) external nonReentrant {
        require(tokenAmount > 0, "Zero amount");
        (uint256 price, ) = _getFreshPrice();
        uint256 usdcOut = (tokenAmount * price) / SCALER;
        require(usdcOut > 0, "Too little");
        require(USDC.balanceOf(address(this)) >= usdcOut, "Insufficient USDC liquidity");
         _burn(msg.sender, tokenAmount);
        require(USDC.transfer(msg.sender, usdcOut), "USDC transfer failed");
        emit Sold(msg.sender, tokenAmount, usdcOut, price);
    }
}
