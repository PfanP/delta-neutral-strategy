// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

// DN Math Library
import {DeltaNeutralMathLib} from "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import {DeltaNeutralMetadata} from "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import "../../lib/dn-chad-math/DopeAssMathLib.sol";

// Import Homora Farm Functions
import {HomoraFarmHandler} from "../contracts/homora/HomoraFarmHandler.sol";
import {HomoraFarmSimulator} from "../contracts/homora/HomoraFarmSimulator.sol";

// Import Swapper Functions
import {UniswapV2Swapper} from "../contracts/swapper/UniswapV2Swapper.sol";

// These are the core Yearn libraries
import {BaseStrategy, StrategyParams} from "./yearn/BaseStrategy.sol";
import "../interfaces/IHomoraFarmHandler.sol";
import "../interfaces/oracle/IConcaveOracle.sol";
import "../interfaces/IERC1155.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Import interfaces for many popular DeFi projects, or add your own!
//import "./interfaces/<protocol>/<Interface>.sol";

contract MockStrategy is BaseStrategy, HomoraFarmHandler, UniswapV2Swapper {
    using SafeERC20 for IERC20;
    using Address for address;
    using DeltaNeutralMathLib for DeltaNeutralMetadata;
    using DopeAssMathLib for uint256;

    uint private constant MULTIPLIER = 10000; // (10000 = 100% = 1)
    uint private constant WAD = 1e18;

    // The token pairs which will go into the Homora Farm
    address public concaveOracle;
    address public ethTokenAddress;
    address private token0; // Token0 is the long token
    address private token1; // Token1 is the shorted token
    address private lpToken;
    uint private pid; // The Pool ID Input to Homora
    
    uint private farmLeverage;
    uint private longPositionId;
    uint private shortPositionId;

    event Tended();
    
    //// DEBUG EVENTS ////
    event debugBool(bool emitBool);
    //event debugString(string str);

    // solhint-disable-next-line no-empty-blocks
    constructor(
        address _vault,
        address _homoraBank,
        address _sushiSwapSpell,
        address _uniswapV2Router,
        address _token1,
        uint _farmLeverage, // Farm Leverage in units of 1e18
        address _concaveOracle,
        address _lpToken,
        uint _pid,
        address _ethTokenAddress
    ) BaseStrategy(_vault) 
    HomoraFarmHandler(_homoraBank, _sushiSwapSpell) 
    UniswapV2Swapper(_uniswapV2Router)
    {
        // You can set these parameters on deployment to whatever you want
        // maxReportDelay = 6300;
        // profitFactor = 100;
        // debtThreshold = 0;

        token0 = vault.token(); // Token 0 is always the want token
        token1 = _token1;
        farmLeverage = _farmLeverage;
        longPositionId = 0;
        shortPositionId = 0;
        concaveOracle = _concaveOracle;
        lpToken = _lpToken;
        pid = _pid;
        ethTokenAddress = _ethTokenAddress;
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function setLongPositionId(uint _longPositionId) external onlyStrategist {
        longPositionId = _longPositionId;
    }

    function setShortPositionId(uint _shortPositionId) external onlyStrategist {
        shortPositionId = _shortPositionId;
    }

    function name() external view override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "Strategy<ProtocolName><TokenType>";
    }

    // Balances of the tokens in the strategy + value of the 2 DN positions open
    function estimatedTotalAssets() public view override returns (uint256) {
        return want.balanceOf(address(this)) +
            getCollateralETHValue(longPositionId) +
            getCollateralETHValue(shortPositionId) -
            getBorrowETHValue(longPositionId) - 
            getBorrowETHValue(shortPositionId);
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    // solhint-disable-next-line no-empty-blocks
    {
        // TODO: Do stuff here to free up any returns back into `want`
        // NOTE: Return `_profit` which is value generated by all positions, priced in `want`
        // NOTE: Should try to free up at least `_debtOutstanding` of underlying position

        if (longPositionId != 0 && shortPositionId != 0) {
            harvestSushiswap(longPositionId);
            harvestSushiswap(shortPositionId);
            // swap sushi token into the want token
            uint256 amountIn = getSushi().balanceOf(address(this));
            swap(address(getSushi()), amountIn, address(want), address(this));

            uint256 totalAssets = estimatedTotalAssets();
            uint256 totalDebt = vault.strategies(address(this)).totalDebt;
            _debtPayment = 0;
            if (totalAssets > totalDebt) {
                _profit = totalAssets - totalDebt;
            } else {
                _loss = totalDebt - totalAssets;
            }
        } else { // This is the case for opening fresh positions
            _profit = 0;
            _loss = 0;
            _debtPayment = 0;
        }
    }
    function prepareRebalance(uint256 _debtOutstanding) 
        internal 
        override
        returns (
            uint256 _profit, // Gain goes towards totalAvail
            uint256 _loss, // Loss results in less debt ratio and less locked profit
            uint256 _debtPayment // in the vault report() function: Min(debtOutstanding, debtPayment)
        ) 
    {   // totalAvail = profit + debtpayment | creditAvail = how much the vault is under debt limit | Only looks at the harvest pot
        _profit = 0;
        _loss = 0;
        _debtPayment = 0; 
    }

    function tend(bool _overrideMode) external override onlyKeepers
    returns (
        uint longLpRemove,
        uint longLpLoanPayback,
        uint shortLpRemove,
        uint shortLpLoanPayback,
        uint action3LpTokenBal,
        uint longLoanIncrase,
        uint shortLoanIncrease
    )
      {

        if (emergencyExit) {
            uint256 debtOutstanding = vault.debtOutstanding(); // How much the vault expects the strategy to pay back
            uint profit = 0;
            uint loss = 0;
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding - amountFreed;
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed - debtOutstanding;
            }
            uint debtPayment = debtOutstanding - loss;
            debtOutstanding = vault.report(profit, loss, debtPayment); 
        } else {
            // The usual flow
            if (!_overrideMode) { 
                vault.report(0, 0, 0); // Set Profit, loss, debtpayment all to 0
                emit debugString('Finish Vault Report');
                
                (uint longLpRemove,
                uint longLpLoanPayback,
                uint shortLpRemove,
                uint shortLpLoanPayback,
                uint action3LpTokenBal,
                uint longLoanIncrase,
                uint shortLoanIncrease) = 
                rebalancePosition();
            } else {
                // In override mode, just adjust the position and chill about 
                // everything else
                rebalancePosition();
            }
        }
        emit Tended();
    }

    function rebalancePosition() internal 
    returns (
        uint longLpRemove,
        uint longLpLoanPayback,
        uint shortLpRemove,
        uint shortLpLoanPayback,
        uint action3LpTokenBal,
        uint longLoanIncrase,
        uint shortLoanIncrease
    )
     {
        uint256 liquidityInjection = 0;

        DeltaNeutralMetadata memory data;
        uint256 longLoanValue    = getBorrowETHValue(longPositionId);
        uint256 shortLoanValue   = getBorrowETHValue(shortPositionId);
        data = DeltaNeutralMetadata(
            getCollateralETHValue(longPositionId) - longLoanValue, //longEquityValue
            longLoanValue,
            getCollateralETHValue(shortPositionId) - shortLoanValue, //shortEquityValue
            shortLoanValue,
            liquidityInjection,
            farmLeverage
        );

        uint256 desiredAdjustment = data.getDesiredAdjustment(); 
        RebalanceData memory rebalanceData;

        rebalanceData = RebalanceData(
            data.longEquityRebalanceTarget(desiredAdjustment),
            data.longEquityValue,
            data.longLoanRebalanceTarget(desiredAdjustment),
            data.longLoanValue,
            data.shortEquityRebalanceTarget(desiredAdjustment),
            data.shortEquityValue,
            data.shortLoanRebalanceTarget(desiredAdjustment),
            data.shortLoanValue
        );
        (
        uint longLpRemove,
        uint longLpLoanPayback,
        uint shortLpRemove,
        uint shortLpLoanPayback,
        uint action3LpTokenBal,
        uint longLoanIncrase,
        uint shortLoanIncrease) = 
        performRebalance(rebalanceData);
    }

    struct RebalanceData {
        uint256 longEquityTarget;
        uint256 longEquityValue;
        uint256 longLoanTarget;
        uint256 longLoanValue;
        uint256 shortEquityTarget;
        uint256 shortEquityValue;
        uint256 shortLoanTarget;
        uint256 shortLoanValue;
    }

    function performRebalance(
        RebalanceData memory data
    ) internal returns (
        uint longLpRemove,
        uint longLpLoanPayback,
        uint shortLpRemove,
        uint shortLpLoanPayback,
        uint action3LpTokenBal,
        uint longLoanIncrase,
        uint shortLoanIncrease
    ) {
        (,,,uint256 longLpTokenAmount) = getPositionInfo(longPositionId);
        (,,,uint256 shortLpTokenAmount) = getPositionInfo(shortPositionId);

        if (data.longEquityTarget < data.longEquityValue) {
            uint longLpRemove = longLpTokenAmount * (MULTIPLIER * (data.longEquityValue - data.longEquityTarget) / (data.longEquityValue + data.longLoanValue)) / MULTIPLIER; 
            uint256 longLpLoanPayback = 0;
            if (data.longLoanTarget < data.longLoanValue) {
                longLpLoanPayback = longLpTokenAmount * (MULTIPLIER * (data.longLoanValue - data.longLoanTarget)) / (data.longEquityValue + data.longLoanValue) / MULTIPLIER;                
                if (longLpRemove < longLpLoanPayback) {
                    longLpLoanPayback = longLpRemove;
                }

            } 
            // LP Remove and Loan Pay on long Pos
            reducePositionSushiswap(
                longPositionId, 
                token0, 
                token1, 
                longLpRemove, //amtTake
                0, //amtWithdraw = 0 because we want to keep the LP tokens
                0, // Repay token0
                0, // Repay token1
                longLpLoanPayback // Repay in LP amounts
            ); 
            emit debugUint(1);
        }

        // Reduce the short equity position if necessary
        if (data.shortEquityTarget < data.shortEquityValue) {
            uint shortLpRemove = shortLpTokenAmount * (MULTIPLIER * (data.shortEquityValue - data.shortEquityTarget) / data.shortEquityValue) / MULTIPLIER; 
            uint extraLPBal = 0;
            uint shortLpLoanPayback = 0;
            // Calculate the loan payback in LP units
            if (data.shortLoanTarget < data.shortLoanValue) {
                shortLpLoanPayback = MULTIPLIER * (data.shortLoanValue - data.shortLoanTarget) / data.shortLoanValue / MULTIPLIER;
                if ((shortLpRemove + extraLPBal) < shortLpLoanPayback) {
                    shortLpLoanPayback = shortLpRemove + extraLPBal;
                }
            } 
            // LP Remove and Loan Pay on short Pos
            reducePositionSushiswap(
                shortPositionId, 
                token0, 
                token1, 
                shortLpRemove, //amtTake
                0, //amtWithdraw = 0 because we want to keep the LP tokens
                0, // Repay token0
                0, // Repay token1
                shortLpLoanPayback // Repay in LP amounts
            ); 
        }
        
        uint action3LpTokenBal = 0;
        if (action3LpTokenBal > 0 && data.longLoanTarget < getBorrowETHValue(longPositionId)) {
                reducePositionSushiswap(
                    longPositionId, 
                    token0, 
                    token1, 
                    0, //amtTake
                    0, //amtWithdraw = 0 because we want to keep the LP tokens
                    0, // Repay token0
                    0, // Repay token1
                    action3LpTokenBal // Repay in LP amounts
                );
        }

        ///// ACTION 4 /////
        // Increase the long position loan if needed
        data.longLoanValue = getBorrowETHValue(longPositionId);

        if (data.longLoanValue < data.longLoanTarget) {
            (uint longLoanTakeUnits, ) = IConcaveOracle(concaveOracle).getPrice(
                ethTokenAddress,
                token0
            );
            uint longLoanIncrease = 0;

            longLoanIncrease = longLoanTakeUnits * (data.longLoanTarget - data.longLoanValue); // Token 0
            openOrIncreasePositionSushiswap(
                longPositionId, 
                token0,
                token1,
                0, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                longLoanIncrease,
                0,
                pid // Place in the Sushiswap PID
            );
        }

        data.shortLoanValue = getBorrowETHValue(shortPositionId);

        if (data.shortLoanValue < data.shortLoanTarget) {
            (uint shortLoanTakeUnits, ) = IConcaveOracle(concaveOracle).getPrice(
                ethTokenAddress,
                token1
            );

            uint shortLoanIncrease = shortLoanTakeUnits * (data.shortLoanTarget - data.shortLoanValue); // Token 1
            openOrIncreasePositionSushiswap(
                shortPositionId, 
                token0,
                token1,
                0, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                0,
                shortLoanIncrease,
                pid
            );
        }

    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // Get these values all from a homora view function
        uint256 longLoanValue    = getBorrowETHValue(longPositionId);
        uint256 shortLoanValue   = getBorrowETHValue(shortPositionId);
        uint256 longEquityValue  = getCollateralETHValue(longPositionId) - longLoanValue;
        uint256 shortEquityValue = getCollateralETHValue(shortPositionId) - shortLoanValue;

        (uint wantTokenUnits,) = IConcaveOracle(concaveOracle).getPrice(
            address(want),
            ethTokenAddress
        );
        uint256 harvestValue = (want.balanceOf(address(this))) * wantTokenUnits / WAD;

        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            longEquityValue,
            longLoanValue,
            shortEquityValue,
            shortLoanValue,
            harvestValue,
            farmLeverage
        );

        uint desiredAdjustment = data.getDesiredAdjustment();
        uint longEquityAdd = data.getLongEquityAdd(desiredAdjustment);
        uint longLoanAdd = data.getLongLoanAdd(desiredAdjustment);
        uint shortEquityAdd = data.getShortEquityAdd(desiredAdjustment);
        uint shortLoanAdd = data.getShortLoanAdd(desiredAdjustment);
        
        (uint token0Units, ) = IConcaveOracle(concaveOracle).getPrice(
            ethTokenAddress,
            token0
        );

        longEquityAdd = (longEquityAdd * token0Units) / WAD;
        longLoanAdd = (longLoanAdd * token0Units) / WAD;
        uint longPositionIdReturn = openOrIncreasePositionSushiswap(
                longPositionId, 
                token0,
                token1,
                longEquityAdd, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                longLoanAdd,
                0, // 0 Borrrow of token1
                pid
        ); 

        (uint token1Units, ) = IConcaveOracle(concaveOracle).getPrice(
            ethTokenAddress,
            token1
        );
        shortEquityAdd = shortEquityAdd * token0Units / WAD;
        shortLoanAdd = shortLoanAdd * token1Units / WAD;
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 totalAssets = estimatedTotalAssets();
        uint256 lpRemoveProportion;

        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            lpRemoveProportion = MULTIPLIER; // 100%
            unchecked {
                _loss = _amountNeeded - totalAssets;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
            lpRemoveProportion = _liquidatedAmount * MULTIPLIER / totalAssets;
        }

        // Remove the LPs in proportion to _amountNeeded / totalAssets
        // (50% from the long position, 50% from the short position)

        uint256 longLpTokenAmount = 0;
        uint256 shortLpTokenAmount = 0;
        
        (,,,longLpTokenAmount) = getPositionInfo(longPositionId);
        (,,,shortLpTokenAmount) = getPositionInfo(shortPositionId);

        // Payment of debts is in proportion to the farm leverage

        uint256 removeLongLpAmount = longLpTokenAmount * lpRemoveProportion / (2 * MULTIPLIER);
        uint256 removeShortLpAmount = shortLpTokenAmount * lpRemoveProportion / (2 * MULTIPLIER);

        // AmtTake should be equal to AmtWithdraw - if they're unequal we would
        // End up with LP tokens instead of token0 and token1
        // Do a full repay on the position
        reducePositionSushiswap(
            longPositionId, 
            token0, 
            token1, 
            removeLongLpAmount,  //amtTake
            removeLongLpAmount,  //amtWithdraw
            0, 
            0, // Repay the amounts in LP Token
            (WAD * (removeLongLpAmount - removeLongLpAmount) / farmLeverage)
        );

        reducePositionSushiswap(
            shortPositionId, 
            token0, 
            token1, 
            removeShortLpAmount, //amtTake
            removeShortLpAmount, //amtWithdraw
            0, 
            0,
            (WAD * (removeShortLpAmount - removeLongLpAmount) / farmLeverage)
        );

        // swap the token 1 into token 0 here
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));
        if (token1Amount > 0) {
            swap(
                token1,
                token1Amount,
                token0,
                address(this)
            );
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        // TODO: Liquidate all positions and return the amount freed.
        // Ask Homora if there is a simpler liquidate all function to run
        
        (, , , uint longLpTokenAmount) = getPositionInfo(longPositionId);
        (, , , uint shortLpTokenAmount) = getPositionInfo(shortPositionId);
        
        uint[] memory longDebtAmounts = new uint[](2);
        uint[] memory shortDebtAmounts = new uint[](2);
        (,longDebtAmounts) = getPositionDebts(longPositionId);
        (,shortDebtAmounts) = getPositionDebts(shortPositionId);

        // AmtTake should be equal to AmtWithdraw - if they're unequal we would
        // End up with LP tokens instead of token0 and token1
        // Do a full repay on the position
        reducePositionSushiswap(
            longPositionId, 
            token0, 
            token1, 
            longLpTokenAmount,  //amtTake
            longLpTokenAmount,  //amtWithdraw
            longDebtAmounts[0], 
            longDebtAmounts[1],
            0 // No LP Repay
        );

        reducePositionSushiswap(
            shortPositionId, 
            token0, 
            token1, 
            shortLpTokenAmount, //amtTake
            shortLpTokenAmount, //amtWithdraw
            shortDebtAmounts[0], 
            shortDebtAmounts[1],
            0 // No LP Repay
        );

        // swap the token 1 into token 0 here
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));
        if (token1Amount > 0) {
            swap(
                token1,
                token1Amount,
                token0,
                address(this)
            );
        }

        return want.balanceOf(address(this));
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary
    // solhint-disable-next-line no-empty-blocks
    function prepareMigration(address _newStrategy) internal override {
    }
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    // solhint-disable-next-line no-empty-blocks
    {

    }
    
    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // TODO create an accurate price oracle
        return _amtInWei;
    }
}