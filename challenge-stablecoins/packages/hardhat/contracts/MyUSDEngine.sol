// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MyUSD.sol";
import "./Oracle.sol";
import "./MyUSDStaking.sol";

interface IMyUSD {
    function mintTo(address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256); 
    function approve(address spender, uint256 amount) external returns (bool); 
}


error Engine__InvalidAmount();
error Engine__UnsafePositionRatio();
error Engine__NotLiquidatable();
error Engine__InvalidBorrowRate();
error Engine__NotRateController();
error Engine__InsufficientCollateral();
error Engine__TransferFailed();
error Engine__InsufficientBalance();
error Engine__InsufficientAllowance();

contract MyUSDEngine is Ownable {
    uint256 private constant COLLATERAL_RATIO = 150; // 150% collateralization required
    uint256 private constant LIQUIDATOR_REWARD = 10; // 10% reward for liquidators
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant PRECISION = 1e18;

    IMyUSD private i_myUSD;
    Oracle private i_oracle;
    MyUSDStaking private i_staking;
    address private i_rateController;

    uint256 public borrowRate; // Annual interest rate for borrowers in basis points (1% = 100)

    // Total debt shares in the pool
    uint256 public totalDebtShares;

    // Exchange rate between debt shares and MyUSD (1e18 precision)
    uint256 public debtExchangeRate;
    uint256 public lastUpdateTime;

    mapping(address => uint256) public s_userCollateral;
    mapping(address => uint256) public s_userDebtShares;

    event CollateralAdded(address indexed user, uint256 indexed amount, uint256 price);
    event CollateralWithdrawn(address indexed withdrawer, uint256 indexed amount, uint256 price);
    event BorrowRateUpdated(uint256 newRate);
    event DebtSharesMinted(address indexed user, uint256 amount, uint256 shares);
    event DebtSharesBurned(address indexed user, uint256 amount, uint256 shares);
    event Liquidation(
        address indexed user,
        address indexed liquidator,
        uint256 amountForLiquidator,
        uint256 liquidatedUserDebt,
        uint256 price
    );

    modifier onlyRateController() {
        if (msg.sender != i_rateController) revert Engine__NotRateController();
        _;
    }

    constructor(
        address _oracle,
        address _myUSDAddress,
        address _stakingAddress,
        address _rateController
    ) Ownable(msg.sender) {
        i_oracle = Oracle(_oracle);
        i_myUSD = IMyUSD(_myUSDAddress); 
        i_staking = MyUSDStaking(_stakingAddress);
        i_rateController = _rateController;
        lastUpdateTime = block.timestamp;
        debtExchangeRate = PRECISION; 
    }

    // Checkpoint 2: Depositing Collateral & Understanding Value
    function addCollateral() public payable {
        if (msg.value == 0) {
            revert Engine__InvalidAmount();
        }

        s_userCollateral[msg.sender] += msg.value;

        uint256 price = i_oracle.getETHMyUSDPrice();
        emit CollateralAdded(msg.sender, msg.value, price);
    }

    function calculateCollateralValue(address user) public view returns (uint256) {
        uint256 collateralAmount = s_userCollateral[user];
        if (collateralAmount == 0) {
            return 0;
        }
        uint256 ethPrice = i_oracle.getETHMyUSDPrice();

        return (collateralAmount * ethPrice) / PRECISION;
    }

    // Checkpoint 3: Interest Calculation System
    function _getCurrentExchangeRate() internal view returns (uint256) {
        if (totalDebtShares == 0) {
            return debtExchangeRate;
        }
    
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
    
        if (timeElapsed == 0) {
            return debtExchangeRate;
        }
    
        uint256 totalDebtValue = (totalDebtShares * debtExchangeRate) / PRECISION;
    
        uint256 interestAccrued = (totalDebtValue * borrowRate * timeElapsed) / 
                              (SECONDS_PER_YEAR * 10000);
    
        uint256 exchangeRateIncrease = (interestAccrued * PRECISION) / totalDebtShares;
    
        return debtExchangeRate + exchangeRateIncrease;
    }

    function _accrueInterest() internal {
        debtExchangeRate = _getCurrentExchangeRate();

        lastUpdateTime = block.timestamp;
    }

    function _getMyUSDToShares(uint256 amount) internal view returns (uint256) {
        uint256 currentRate = _getCurrentExchangeRate();
    
        uint256 shares = (amount * PRECISION) / currentRate;
    
        return shares;
    }

    // Checkpoint 4: Minting MyUSD & Position Health
    function getCurrentDebtValue(address user) public view returns (uint256) {
        uint256 userShares = s_userDebtShares[user];
        if (userShares == 0) {
            return 0;
        }
    
        uint256 currentRate = _getCurrentExchangeRate();
    
        uint256 debtValue = (userShares * currentRate) / PRECISION;
    
        return debtValue;
    }

    function calculatePositionRatio(address user) public view returns (uint256) {
        uint256 collateralValue = calculateCollateralValue(user);
    
        uint256 debtValue = getCurrentDebtValue(user);
    
        if (debtValue == 0) {
            return type(uint256).max;
        }

        if (collateralValue > type(uint256).max / PRECISION) {
            return type(uint256).max; // Trả về max nếu có overflow risk
        }
    
        uint256 positionRatio = (collateralValue * PRECISION) / debtValue;
    
        return positionRatio;
    }

    function _validatePosition(address user) internal view {
        uint256 positionRatio = calculatePositionRatio(user);
    
        if ((positionRatio * 100) < (COLLATERAL_RATIO * PRECISION)) {
            revert Engine__UnsafePositionRatio();
        }
    }

    function mintMyUSD(uint256 mintAmount) public {
        if (mintAmount == 0) {
            revert Engine__InvalidAmount();
        }

        if (s_userCollateral[msg.sender] == 0) {
            revert Engine__InsufficientCollateral();
        }
    
        uint256 shares = _getMyUSDToShares(mintAmount);
    
        s_userDebtShares[msg.sender] += shares;
    
        totalDebtShares += shares;
    
        _validatePosition(msg.sender);
    
        bool success = i_myUSD.mintTo(msg.sender, mintAmount);
        if (!success) {
            revert Engine__TransferFailed();
        }
    
        emit DebtSharesMinted(msg.sender, mintAmount, shares);
    }

    // Checkpoint 5: Accruing Interest & Managing Borrow Rates
    function setBorrowRate(uint256 newRate) external onlyRateController {
        uint256 currentSavingsRate = i_staking.savingsRate();
        if (newRate < currentSavingsRate) {
            revert Engine__InvalidBorrowRate();
        }
    
        _accrueInterest();
    
        borrowRate = newRate;
    
        emit BorrowRateUpdated(newRate);
    }

    // Checkpoint 6: Repaying Debt & Withdrawing Collateral
    function repayUpTo(uint256 amount) public {
        if (amount == 0) {
            revert Engine__InvalidAmount();
        }
        _accrueInterest();
    
        uint256 userShares = s_userDebtShares[msg.sender];
    
        if (userShares == 0) {
            return;
        }

        uint256 currentRate = _getCurrentExchangeRate();
        if (currentRate == 0) {
            revert Engine__TransferFailed();
        }

        uint256 amountInShares = (amount * PRECISION) / currentRate;

        if (amountInShares > userShares) {
            amountInShares = userShares;
            amount = (userShares * currentRate) / PRECISION;
        } else {
            amount = (amountInShares * currentRate) / PRECISION; 
        }

        uint256 userBalance = i_myUSD.balanceOf(msg.sender);
        if (userBalance < amount) {
            revert Engine__InsufficientBalance(); 
        }
    
        uint256 allowance = i_myUSD.allowance(msg.sender, address(this));
        if (allowance < amount) {
            revert Engine__InsufficientAllowance(); 
        }

    
        s_userDebtShares[msg.sender] -= amountInShares;
        totalDebtShares -= amountInShares;
    
        i_myUSD.burnFrom(msg.sender, amount);
    
        emit DebtSharesBurned(msg.sender, amount, amountInShares);
    }

    function withdrawCollateral(uint256 amount) external {
        if (amount == 0) {
            revert Engine__InvalidAmount();
        }
    
        if (s_userCollateral[msg.sender] < amount) {
            revert Engine__InsufficientCollateral();
        }

        if (address(this).balance < amount) {
            revert Engine__TransferFailed();
        }

    
        s_userCollateral[msg.sender] -= amount;
    
        if (s_userDebtShares[msg.sender] > 0) {
            _validatePosition(msg.sender);
        }
    
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            s_userCollateral[msg.sender] += amount;
            revert Engine__TransferFailed();
        }
    
        uint256 price = i_oracle.getETHMyUSDPrice();
    
        emit CollateralWithdrawn(msg.sender, amount, price);
    }

    // Checkpoint 7: Liquidation - Enforcing System Stability
    function isLiquidatable(address user) public view returns (bool) {
        uint256 positionRatio = calculatePositionRatio(user);
        return (positionRatio * 100) < (COLLATERAL_RATIO * PRECISION);
    }

    function liquidate(address user) external {
        if (!isLiquidatable(user)) {
            revert Engine__NotLiquidatable();
        }
    
        _accrueInterest();
    
        uint256 userDebtValue = getCurrentDebtValue(user);
    
        uint256 userCollateral = s_userCollateral[user];
    
        uint256 collateralValue = calculateCollateralValue(user);
    
        uint256 liquidatorBalance = i_myUSD.balanceOf(msg.sender);
        if (liquidatorBalance < userDebtValue) {
            revert Engine__InsufficientBalance();
        }
    
        uint256 allowance = i_myUSD.allowance(msg.sender, address(this));
        if (allowance < userDebtValue) {
            revert Engine__InsufficientAllowance();
        }
    
        i_myUSD.burnFrom(msg.sender, userDebtValue);
    
        uint256 userDebtShares = s_userDebtShares[user];
    
        s_userDebtShares[user] = 0;
        totalDebtShares -= userDebtShares;
    
        uint256 collateralToCoverDebt;
        if (collateralValue > 0) {
            collateralToCoverDebt = (userDebtValue * userCollateral) / collateralValue;
        } else {
            collateralToCoverDebt = 0;
        }
    
        uint256 rewardAmount = (collateralToCoverDebt * LIQUIDATOR_REWARD) / 100;
    
        uint256 amountForLiquidator = collateralToCoverDebt + rewardAmount;
    
        if (amountForLiquidator > userCollateral) {
            amountForLiquidator = userCollateral;
        }
    
        s_userCollateral[user] -= amountForLiquidator;
    
        (bool success, ) = payable(msg.sender).call{value: amountForLiquidator}("");
        if (!success) {
            s_userCollateral[user] += amountForLiquidator;
            s_userDebtShares[user] = userDebtShares;
            totalDebtShares += userDebtShares;
            revert Engine__TransferFailed();
        }
    
        uint256 price = i_oracle.getETHMyUSDPrice();
    
        emit Liquidation(
            user,
            msg.sender,
            amountForLiquidator,
            userDebtValue,
            price
        );
    }

    function getMaxMintable(address user) public view returns (uint256) {
        uint256 collateralValue = calculateCollateralValue(user);
        uint256 maxDebtValue = (collateralValue * 100) / COLLATERAL_RATIO;
        uint256 currentDebt = getCurrentDebtValue(user);
    
        return currentDebt >= maxDebtValue ? 0 : maxDebtValue - currentDebt;
    }

    function getMaxWithdrawable(address user) public view returns (uint256) {
        uint256 totalCollateral = s_userCollateral[user];
        uint256 debtValue = getCurrentDebtValue(user);
    
        if (debtValue == 0) {
            return totalCollateral;
        }
    
        uint256 requiredCollateralValue = (debtValue * COLLATERAL_RATIO) / 100;
        uint256 ethPrice = i_oracle.getETHMyUSDPrice();
        uint256 requiredCollateral = (requiredCollateralValue * PRECISION) / ethPrice;
    
        return requiredCollateral >= totalCollateral ? 0 : totalCollateral - requiredCollateral;
    }
}
