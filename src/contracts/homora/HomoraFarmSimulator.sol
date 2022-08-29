// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import "../../interfaces/IHomoraBank.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IBaseOracle.sol";
import "../../interfaces/IWMasterChef.sol";
import "../../interfaces/IHomoraSushiSpell.sol";
import {DopeAssMathLib} from "../../../lib/dn-chad-math/DopeAssMathLib.sol";
import {Token} from "../../Token.sol";


/// @title The interface for Alpha Homora Leveraged Yield Farms
/// @notice Operates positons on Homora farms
abstract contract HomoraFarmSimulator {
    /// @notice
    /// @param

    address public immutable homoraBank;
    address public immutable relevantHomoraSpell;
    address public immutable sushiSwapSpell;
    address farmToken = 0x0000000000000000000000000000000000100000;

    uint mockHarvestAmount;
    uint longPositionEquityETH;
    uint shortPositionEquityETH;
    uint longPositionLoanETH;
    uint shortPositionLoanETH;
    uint longLPAmount;
    uint shortLPAmount;

    uint longPositionDebtToken0;
    uint shortPositionDebtToken1;

    uint longPosId;
    uint shortPosId;

    struct Amounts {
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        uint256 amtLPUser; // Supplied LP token amount
        uint256 amtABorrow; // Borrow tokenA amount
        uint256 amtBBorrow; // Borrow tokenB amount
        uint256 amtLPBorrow; // Borrow LP token amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    struct RepayAmounts {
        uint256 amtLPTake; // Take out LP token amount (from Homora)
        uint256 amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint256 amtARepay; // Repay tokenA amount
        uint256 amtBRepay; // Repay tokenB amount
        uint256 amtLPRepay; // Repay LP token amount
        uint256 amtAMin; // Desired tokenA amount
        uint256 amtBMin; // Desired tokenB amount
    }

    constructor(
        address _homoraBank, // Constructor inputs not really used except to parrot the original Farm Handler
        address _relevantHomoraSpell
    ) {
        homoraBank = _homoraBank;
        relevantHomoraSpell = _relevantHomoraSpell;
        sushiSwapSpell = _relevantHomoraSpell;
    }

    function initialize_farmSimulator(
        uint _mockHarvestAmount,
        uint _longPositionEquityETH,
        uint _longPositionLoanETH,
        uint _shortPositionEquityETH,
        uint _shortPositionLoanETH,
        uint _longLPAmount,
        uint _shortLPAmount,
        uint _longPositionDebtToken0,
        uint _shortPositionDebtToken1,
        uint _longPosId,
        uint _shortPosId
    ) external {
        mockHarvestAmount = _mockHarvestAmount;
        longPositionEquityETH = _longPositionEquityETH;
        longPositionLoanETH = _longPositionLoanETH;
        shortPositionEquityETH = _shortPositionEquityETH;
        shortPositionLoanETH = _shortPositionLoanETH;
        longLPAmount = _longLPAmount;
        shortLPAmount = _shortLPAmount;

        longPositionDebtToken0 = _longPositionDebtToken0;
        shortPositionDebtToken1 = _shortPositionDebtToken1;

        longPosId = _longPosId;
        shortPosId = _shortPosId;
    }

    // *** Sushiswap *** //
    // Open a position on SushiSwap thru Homora
    //
    // Position ID is 0 for new positions, non 0 for increase in an existing position
    function openOrIncreasePositionSushiswap(
        uint256 positionID,
        address token0,
        address token1,
        uint256 supplyToken0,
        uint256 supplyToken1,
        uint256 supplyLp,
        uint256 borrowToken0,
        uint256 borrowToken1,
        uint256 pid // pool id
    ) public returns (uint) {
        return positionID;
    }

    function reducePositionSushiswap( 
        uint256 positionID,
        address token0,
        address token1,
        uint256 amtLPTake,
        uint256 amtLPWithdraw,
        uint256 repayAmtToken0,
        uint256 repayAmtToken1,
        uint256 amountLPRepay
    ) public {

    }

    // Sushiswap harvest rewards
    function harvestSushiswap(uint256 positionID) public {
        // Transfer some mock tokens here
    }

    // Sushiswap get pending rewards
    function getPendingRewardForSushiswap(uint256 _positionId)
        public
        view
        returns (uint256)
    {
        return mockHarvestAmount;
    }

    /// @dev Return position information for the given position id.
    /// @param positionId The position id to query for position information.
    function getPositionInfo(uint256 positionId)
        public
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        )
    {   
        if (positionId == longPosId) {
            return (
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0,
                longLPAmount);
        } else if (positionId == shortPosId) {
            return (
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0,
                shortLPAmount);
        } else {
            return (
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0,
                0);        
        }
    }

    /// @dev Return the list of all debts for the given position id.
    /// @param positionId position id to get debts of
    
    function getPositionDebts(uint256 positionId)
        public
        view
        returns (address[] memory tokens, uint256[] memory debts)
    {
        address[] memory emptyArray = new address[](0);
        uint[] memory debtAmounts = new uint[](2);
        if (positionId == longPosId) {
            debtAmounts[0] = longPositionDebtToken0;
            debtAmounts[1] = 0;
        } else if (positionId == shortPosId) {
            debtAmounts[0] = 0;
            debtAmounts[1] = shortPositionDebtToken1;
        } else {
            debtAmounts[0] = 0;
            debtAmounts[1] = 0;
        }

        return (emptyArray,debtAmounts);
    }

    /*
    /// @dev Return the debt share of the given bank token for the given position id.
    /// @param positionId position id to get debt of
    /// @param token ERC20 debt token to query
    
    function getPositionDebtShareOf(uint256 positionId, address token)
        public
        view
        returns (uint256)
    {
        return
            IHomoraBank(homoraBank).getPositionDebtShareOf(positionId, token);
    } 

    /// @dev Return bank information for the given token.
    /// @param token The token address to query for bank information.
    function getBankInfo(address token)
        public
        view
        returns (
            bool isListed,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        )
    {
        return IHomoraBank(homoraBank).getBankInfo(token);
    } 

    /// @dev Check whether the oracle supports the token
    /// @param token ERC-20 token to check for support
    function support(address token) public view returns (bool) {
        return IHomoraBank(homoraBank).support(token);
    }

    /// @dev Return the borrow balance for given position and token without triggering interest accrual.
    /// @param positionId The position to query for borrow balance.
    /// @param token The token to query for borrow balance.
    function borrowBalanceStored(uint256 positionId, address token)
        public
        view
        returns (uint256)
    {
        return IHomoraBank(homoraBank).borrowBalanceStored(positionId, token);
    } */

    /// @dev Return the total collateral value of the given position in ETH.
    /// @param positionId The position ID to query for the collateral value.
    function getCollateralETHValue(uint256 positionId)
        public
        view
        returns (uint256)
    {
        if (positionId == longPosId) {
            return longPositionEquityETH + longPositionLoanETH;
        } else if (positionId == shortPosId) {
            return shortPositionEquityETH + shortPositionLoanETH;
        } else {
            return 0;
        }
    }

    /// @dev Return the total borrow value of the given position in ETH.
    /// @param positionId The position ID to query for the borrow value.
    function getBorrowETHValue(uint256 positionId)
        public
        view
        returns (uint256)
    {
        if (positionId == longPosId) {
            return longPositionLoanETH;
        } else if (positionId == shortPosId) {
            return shortPositionLoanETH;
        } else {
            return 0;
        }
    }

    /// @dev Return the sushi token from the master chef
    function getSushi() public view returns (IERC20) {
        return IERC20(farmToken);
    }

    /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
    /// @param token The ERC-20 token to check the value.
    function getETHPx(address token) public view returns (uint) {
        IBaseOracle oracle = IBaseOracle(IHomoraBank(homoraBank).oracle());
        return oracle.getETHPx(token);
    }

    /// @dev Set farm token
    /// @param token The farm token
    function setFarmToken(address token) external {
        farmToken = token;
    }
}
