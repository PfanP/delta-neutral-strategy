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
import "../interfaces/ISwapperImpl.sol";

contract Strategy is BaseStrategy, HomoraFarmHandler {
    using SafeERC20 for IERC20;
    using Address for address;
    using DeltaNeutralMathLib for DeltaNeutralMetadata;
    using DopeAssMathLib for uint256;

    uint private constant MULTIPLIER = 10000; // (10000 = 100% = 1)

    // The token pairs which will go into the Homora Farm
    address public homoraFarmHandler;
    address public concaveOracle;
    address public ethTokenAddress;
    address private token0; // Token0 is the long token
    address private token1; // Token1 is the shorted token
    address private lpToken;
    address public swapper;

    uint private farmLeverage;
    uint private longPositionId;
    uint private shortPositionId;

    event Tended(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    // solhint-disable-next-line no-empty-blocks
    constructor(
        address _vault,
        address _homoraBank,
        address _sushiSwapSpell,
        address _swapper,
        address _token0,
        address _token1,
        uint _farmLeverage,
        address _concaveOracle,
        address _lpToken
    ) BaseStrategy(_vault) 
    HomoraFarmHandler(_homoraBank, _sushiSwapSpell) 
    {
        // You can set these parameters on deployment to whatever you want
        // maxReportDelay = 6300;
        // profitFactor = 100;
        // debtThreshold = 0;

        token0 = _token0;
        token1 = _token1;
        farmLeverage = _farmLeverage;
        swapper = _swapper;
        longPositionId = 0;
        shortPositionId = 0;
        concaveOracle = _concaveOracle;
        lpToken = _lpToken;

        // approve tokens to the swapper
        IERC20(token1).safeApprove(swapper, type(uint256).max);
        getSushi().safeApprove(swapper, type(uint256).max);
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

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

        harvestSushiswap(longPositionId);
        harvestSushiswap(shortPositionId);

        // swap sushi token into the want token
        uint256 amountIn = getSushi().balanceOf(address(this));
        ISwapperImpl(swapper).swap(address(getSushi()), amountIn, address(want), address(this));

        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        _debtPayment = 0;
        // if (totalAssets > _debtOutstanding) {
        //     _debtPayment = _debtOutstanding;
        //     totalAssets = totalAssets - _debtOutstanding;
        // } else {
        //     _debtPayment = totalAssets;
        //     totalAssets = 0;
        // }
        // totalDebt = totalDebt - _debtPayment;

        if (totalAssets > totalDebt) {
            _profit = totalAssets - totalDebt;
        } else {
            _loss = totalDebt - totalAssets;
        }
    }

    // ******** AUTHOR 0xQuasar ******** //
    // * Prepare for the DN rebalancing // 
    // * No Harvesting from the Farms, save on some gas. 
    // * 
    // * When tending always pay back the amount the vault wants in debtOutstanding\
    // * Profits and losses are the figures since the last report 
    // debtOutstanding is how much the vault expects the strategy to pay back
    function prepareRebalance(uint256 _debtOutstanding) 
        internal 
        override
        returns (
            uint256 _profit, // Gain goes towards totalAvail
            uint256 _loss, // Loss results in less debt ratio and less locked profit
            uint256 _debtPayment // in the vault report() function: Min(debtOutstanding, debtPayment)
        ) 
    {   // totalAvail = profit + debtpayment | creditAvail = how much the vault is under debt limit | Only looks at the harvest pot

        // Pay back the vault when the debt limit goes down - yes
        // Take more money from the vault? - No that is taken care of in def report()
        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt   = vault.strategies(address(this)).totalDebt;

        if (totalAssets > totalDebt) {
            _profit = totalAssets - totalDebt;
        } else {
            _loss = totalDebt - totalAssets;
        }
        _debtPayment = _debtOutstanding;
    }

    function tend(bool _overrideMode) internal override {
        uint256 debtOutstanding = vault.debtOutstanding(); // How much the vault expects the strategy to pay back
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtPayment = 0; // Amount to pay back to the vault 

        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
            debtOutstanding = vault.report(profit, loss, debtPayment); // Send tokens to Vault
        } else {
            // The usual flow
            if (!_overrideMode) { 
                // Do the calls on the position
                (profit, loss, debtPayment) = prepareRebalance(debtOutstanding); // debtPayment always equals debtOutstanding here

                if (debtOutstanding > 0) { // We gonna have to pay the vault
                    rebalancePosition(debtOutstanding);
                    // This is where the strategy either pays the vault or gets credit tokens from vault        
                    debtOutstanding = vault.report(profit, loss, debtPayment);
                } else { // The Vault is gonna pay us (or no tokens to be transferred)
                    debtOutstanding = vault.report(profit, loss, debtPayment);
                    rebalancePosition(debtOutstanding);
                }
            } else {
                // In override mode, just adjust the position and chill about 
                // everything else
                rebalancePosition(0);
            }
        // In this particular DN tend strategy we need to know beforehand whether we pay
        // the vault or the vault pays us. 
        // If vault pays us, we need the tokens before performing rebalance. 
        // If we pay the vault, the rebalance will free the tokens and we'll have the tokens
        // after. 

        // There's a problem tho - in the vault, the credit to or debit from strategy 
        // is done in the report. 
        // That means - we need to know when to call the report - before or after adjustPosition. 
        // Cuz it will depend on the case. 

        // Need to figure out here beforehand whether the vault is gonna pay us,
        // Or if we are going to need to pay the vault. 
        // That consideration will be fulfilled mostly by: 
        // Knowing what our debtLimit is, and whether we are over or under it. 
        // >>> Actually the debtOutstanding takes care of that. If it is 0, the vault 
        // is probably going to pay us and we should expect that. If it is > 0, then 
        // We are gonna need to pay the vault. 

        // I will add a rebalancing override mode where these considerations are neglected
        // In case a bug here jams the mechanism, we can still rebalance. 

        // ********
        // Still need some health check stuff here

        emit Tended(profit, loss, debtPayment, debtOutstanding);

    }


    // Add: Function to change the farm leverage // TODO 

    // ********* For Homora - Sushiswap ********** 
    // solhint-disable-next-line no-empty-blocks
    function rebalancePosition(uint256 _debtOutstanding) internal {
        // TODO: Do something to invest excess `want` tokens (from the Vault) into your positions
        // NOTE: Try to adjust positions so that `_debtOutstanding` can be freed up on *next* harvest (not immediately)
        
        DeltaNeutralMetadata memory data;
        
        // Values in ETH
        uint256 longLoanValue    = getBorrowETHValue(longPositionId);
        uint256 shortLoanValue   = getBorrowETHValue(shortPositionId);
        uint256 longEquityValue  = getCollateralETHValue(longPositionId) - longLoanValue;
        uint256 shortEquityValue = getCollateralETHValue(shortPositionId) - shortLoanValue;

        data = DeltaNeutralMetadata(
            longEquityValue,
            longLoanValue,
            shortEquityValue,
            shortLoanValue,
            0,  // No harvest in tend function
            farmLeverage
        );
        
        // All values here valuated in ETH
        uint256 desiredAdjustment = data.getDesiredAdjustment(); 
        uint256 longEquityTarget = data.longEquityRebalanceTarget(desiredAdjustment);
        uint256 longLoanTarget = data.longLoanRebalanceTarget(desiredAdjustment);
        uint256 shortEquityTarget = data.shortEquityRebalanceTarget(desiredAdjustment);
        uint256 shortLoanTarget = data.shortLoanRebalanceTarget(desiredAdjustment);
        
        performRebalance(
            longEquityTarget,
            longEquityValue,
            longLoanTarget,
            longLoanValue,
            shortEquityTarget,
            shortEquityValue,
            shortLoanTarget,
            shortLoanValue
        );
               
        // Rebalancing: Say Eth price goes up
        // This short farm is underlevereaged now

        // This farm is overleveraged in the case ETH price goes up
        // Need to move funds from this position into long position 
        // Harvesting: 2 goals: (1) Maintain ratio of the base assets in the positions
        // (2) Maintain the farm leverage
        // Rebalance action: (1) Pull liquidity from one farm and deposit in other
        // (2) Take out loans in the one that got liquidity pulled
        // NOTE: Reduce the underleverage farm supply without 
        // Paying the loan back. This will reduce number of actions. 
        // 
        // Rebalance trigger conditions on chain
        // Rebalance calcs & mechanism also on chain
        // Condition detection can happen off chain in a bot
    }

    function performRebalance(
        uint256 longEquityTarget,
        uint256 longEquityValue,
        uint256 longLoanTarget,
        uint256 longLoanValue,
        uint256 shortEquityTarget,
        uint256 shortEquityValue,
        uint256 shortLoanTarget,
        uint256 shortLoanValue
    ) internal {
        // ACTIONS: 
        // 1. Reduce Position 0 and Payback loan as necessary
        // 2. Reduce Position 1 and Payback loan as necessary
        // 3. Payback loan on Position 0 again as necessary
        // 4. Increase loan on position 0 if needed
        // 5. Increase loan on position 1 if needed

        // Get Position LP Amounts
        (,,,uint256 longLpTokenAmount) = getPositionInfo(longPositionId);
        (,,,uint256 shortLpTokenAmount) = getPositionInfo(shortPositionId);

        //// ACTION 1 ////
        // Reduce the long equity position if necessary
        if (longEquityTarget < longEquityValue) {
            // Calculate the Proportion of LP that corresponds to the percentage 
            uint256 longLpRemove = longLpTokenAmount * ((longEquityValue - longEquityTarget) / longEquityValue); 
            // Calculate the loan payback in LP units
            uint longLpLoanPayback = 0;
            if (longLoanTarget < longLoanValue) {
                longLpLoanPayback = (longLoanValue - longLoanTarget) / longLoanValue;
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
        }

        //// ACTION 2 ////
        // Reduce the short equity position if necessary
        if (shortEquityTarget < shortEquityValue) {
            uint shortLpRemove = shortLpTokenAmount * ((shortEquityValue - shortEquityTarget) / shortEquityValue); 
            
            // TODO: Redefine the lpToken var - ID needs figuring
            uint extraLPBal = IERC1155(lpToken).balanceOf(address(this), 0);  

            // Calculate the loan payback in LP units
            uint shortLpLoanPayback = 0;
            if (shortLoanTarget < shortLoanValue) {
                shortLpLoanPayback = (shortLoanValue - shortLoanTarget) / shortLoanValue;
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

        ///// ACTION 3 /////
        // Do another payback on the longLoanPosition if needed
        // NOTE: Maybe need to add a statement here to prevent overpaying the loan
        
        // TODO: Redefine the lpToken var - ID needs figuring
        uint action3LpTokenBal = IERC1155(lpToken).balanceOf(address(this), 0);
        if (action3LpTokenBal > 0 && longLoanTarget < getBorrowETHValue(longPositionId)) {
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
        longLoanValue = getBorrowETHValue(longPositionId);

        if (longLoanValue < longLoanTarget) {
            (uint longLoanTake, ) = IConcaveOracle(concaveOracle).getPrice(
                ethTokenAddress,
                token0
            );
            longLoanTake = longLoanTake * (longLoanTarget - longLoanValue);
            openOrIncreasePositionSushiswap(
                longPositionId, 
                token0,
                token1,
                0, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                longLoanTake, // Token 0
                0,
                0 // Place in the Sushiswap PID
            );
        }

        ///// ACTION 5 /////
        // Increase the short position loan if needed
        shortLoanValue = getBorrowETHValue(shortPositionId);

        if (shortLoanValue < shortLoanTarget) {
            (uint shortLoanTake, ) = IConcaveOracle(concaveOracle).getPrice(
                ethTokenAddress,
                token1
            );
            shortLoanTake = shortLoanTake * (shortLoanTarget - shortLoanValue);

            openOrIncreasePositionSushiswap(
                shortPositionId, 
                token0,
                token1,
                0, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                0,
                shortLoanTake, // Token 1
                0 // Place in the Sushiswap PID
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
            ethTokenAddress,
            address(want)
        );
        uint256 harvestValue = (want.balanceOf(address(this))) * wantTokenUnits;

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
        uint shortLoadAdd = data.getShortLoanAdd(desiredAdjustment);


        (uint token0Units, ) = IConcaveOracle(concaveOracle).getPrice(
            ethTokenAddress,
            token0
        );
        (uint token1Units, ) = IConcaveOracle(concaveOracle).getPrice(
            ethTokenAddress,
            token1
        );

        longEquityAdd = longEquityAdd * token0Units;
        longLoanAdd = longLoanAdd * token0Units;
        // Call Add Position
        // Position Long
        uint longPositionIdReturn = openOrIncreasePositionSushiswap(
                longPositionId, 
                token0,
                token1,
                longEquityAdd, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                longLoanAdd,
                0, // 0 Borrrow of token1
                0 // Place in the Sushiswap PID
        );
        // Rebalancing: Say Eth price goes up
        // This farm is underlevereaged now

        shortEquityAdd = shortEquityAdd * token0Units;
        shortLoadAdd = shortLoadAdd * token1Units;
        // Position Two
        uint shortPositionIdReturn = openOrIncreasePositionSushiswap(
                shortPositionId, 
                token0,
                token1,
                shortEquityAdd,
                0,
                0, // 0 Supply of LP
                0, // 0 Borrow of token0
                shortLoadAdd,
                0 // Place in the Sushiswap PID
        );

        // Update the position IDs if opening new DN positions
        if (longPositionId == 0 && shortPositionId == 0) {
            longPositionId = longPositionIdReturn;
            shortPositionId = shortPositionIdReturn;
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // TODO: Do stuff here to free up to `_amountNeeded` from all positions back into `want`
        // NOTE: Maintain invariant `want.balanceOf(this) >= _liquidatedAmount`
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`

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
            (removeLongLpAmount - removeLongLpAmount / farmLeverage)
        );

        reducePositionSushiswap(
            shortPositionId, 
            token0, 
            token1, 
            removeShortLpAmount, //amtTake
            removeShortLpAmount, //amtWithdraw
            0, 
            0,
            (removeShortLpAmount - removeLongLpAmount / farmLeverage)
        );

        // swap the token 1 into token 0 here
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));
        if (token1Amount > 0) {
            ISwapperImpl(swapper).swap(
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
            ISwapperImpl(swapper).swap(
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
        // TODO: Transfer any non-`want` tokens to the new strategy
        // NOTE: `migrate` will automatically forward all `want` in this strategy to the new one
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistent* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
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
