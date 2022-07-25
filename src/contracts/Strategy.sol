// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

// DN Math Library
import {DeltaNeutralMathLib} from "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import {DeltaNeutralMetadata} from "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";

// These are the core Yearn libraries
import {BaseStrategy, StrategyParams} from "./yearn/BaseStrategy.sol";
import "../interfaces/IHomoraFarmHandler.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Import interfaces for many popular DeFi projects, or add your own!
//import "./interfaces/<protocol>/<Interface>.sol";

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using DeltaNeutralMathLib for DeltaNeutralMetadata;

    // The token pairs which will go into the Homora Farm
    address public homoraFarmHandler;
    address private token0;
    address private token1;
    uint private farmLeverage;
    uint private longPositionId;
    uint private shortPositionId;

    // solhint-disable-next-line no-empty-blocks
    constructor(
        address _vault
        //address _token0,
        ///address _token1,
        ///uint _farmLeverage,
        //address _homoraFarmHandler
    ) BaseStrategy(_vault) {
        // You can set these parameters on deployment to whatever you want
        // maxReportDelay = 6300;
        // profitFactor = 100;
        // debtThreshold = 0;
        /*
        token0 = _token0;
        token1 = _token1;
        farmLeverage = _farmLeverage;
        homoraFarmHandler = _homoraFarmHandler;
        posId0 = 0;
        posId1 = 0;*/ 
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external view override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "Strategy<ProtocolName><TokenType>";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        // TODO: Build a more accurate estimate using the value of all positions in terms of `want`
        return want.balanceOf(address(this));
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

        IHomoraFarmHandler(homoraFarmHandler).harvestSushiswap(posId0);
        IHomoraFarmHandler(homoraFarmHandler).harvestSushiswap(posId1);

        uint256 totalAssets = want.balanceOf(address(this));
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        if (totalAssets > _debtOutstanding) {
            _debtPayment = _debtOutstanding;
            totalAssets = totalAssets - _debtOutstanding;
        } else {
            _debtPayment = totalAssets;
            totalAssets = 0;
        }
        totalDebt = totalDebt - _debtPayment;

        if (totalAssets > totalDebt) {
            _profit = totalAssets - totalDebt;
        } else {
            _loss = totalDebt - totalAssets;
        }
    }

    // Add: Function to change the farm leverage // TODO 

    // ********* For Homora - Sushiswap ********** 
    // solhint-disable-next-line no-empty-blocks
    function adjustPosition(uint256 _debtOutstanding) internal override {
        // TODO: Do something to invest excess `want` tokens (from the Vault) into your positions
        // NOTE: Try to adjust positions so that `_debtOutstanding` can be freed up on *next* harvest (not immediately)
        
        // Balance of the free tokens in the strategy
        uint256 freeTokens = want.balanceOf(address(this));
        // Call a harvest and add the harvest to the free token balance

        // Get these values all from a homora view function
        uint longEquityValue;
        uint longLoanValue;
        uint shortEquityValue;
        uint shortLoanValue; 
        uint harvestValue; 

        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            longEquityValue,
            longLoanValue,
            shortEquityValue,
            shortLoanValue,
            harvestValue,
            farmLeverage
        );

        uint desiredAdjustment = data.getDesiredAdjustment();
        uint longPositionEquityAdd = data.longEquityRebalance(desiredAdjustment);
        uint longPositionBorrowAdd = data.longLoanRebalance(desiredAdjustment);
        uint shortPositionEquityAdd = data.shortEquityRebalance(desiredAdjustment);
        uint shortPositionLoanAdd = data.shortLoanRebalance(desiredAdjustment);

        // Manage the allowances of this contract to Homora Farm Handler

        // Call Reduce Position


        // Call Add Position
        // Position Long
        uint longPositionIdReturn = IHomoraFarmHandler(homoraFarmHandler).openOrIncreasePositionSushiswap(
                longPositionId, 
                token0,
                token1,
                longPositionEquityAdd, // amountToken0
                0, // amountToken1 will be 0
                0, // 0 LP Supplied
                longPositionBorrowAdd,
                0, // 0 Borrrow of token1
                0 // Place in the Sushiswap PID
        );
        // Rebalancing: Say Eth price goes up
        // This farm is underlevereaged now

        // Position Two
        uint shortPositionIdReturn = IHomoraFarmHandler(homoraFarmHandler).openOrIncreasePositionSushiswap(
                shortPositionId, 
                token0,
                token1,
                shortPositionEquityAdd,
                0,
                0, // 0 Supply of LP
                0, // 0 Borrow of token0
                shortPositionLoanAdd,
                0 // Place in the Sushiswap PID
        );
        // This farm is overleveraged in the case ETH price goes up
        // Need to move funds from this position into long position 
        // Harvesting: 2 goals: (1) Maintain ratio of the base assets in the positions
        // (2) Maintain the farm leverage
        // Rebalance action: (1) Pull liquidity from one farm and deposit in other
        // (2) Take out loans in the one that got liquidity pulled
        // NOTE: If possible, reduce the underleverage farm supply without 
        // Paying the loan back. This will reduce number of actions. 
        // 
        // Rebalance trigger conditions on chain
        // Rebalance calcs & mechanism also on chain
        // Condition detection can happen off chain in a bot

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

        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            unchecked {
                _loss = _amountNeeded - totalAssets;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        // TODO: Liquidate all positions and return the amount freed.
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
