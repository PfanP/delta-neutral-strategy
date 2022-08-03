// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "../../interfaces/IHomoraBank.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../interfaces/IWMasterChef.sol';
import '../../interfaces/IHomoraSushiSpell.sol';
import {DopeAssMathLib} from "../../../lib/dn-chad-math/DopeAssMathLib.sol";


/// @title The interface for Alpha Homora Leveraged Yield Farms
/// @notice Operates positons on Homora farms
contract HomoraFarmHandler {
    /// @notice
    /// @param 

    address public immutable homoraBank;
    address public immutable sushiSwapSpell;
    address public immutable uniswapV2Spell;

    struct Amounts {
        uint amtAUser; // Supplied tokenA amount
        uint amtBUser; // Supplied tokenB amount
        uint amtLPUser; // Supplied LP token amount
        uint amtABorrow; // Borrow tokenA amount
        uint amtBBorrow; // Borrow tokenB amount
        uint amtLPBorrow; // Borrow LP token amount
        uint amtAMin; // Desired tokenA amount (slippage control)
        uint amtBMin; // Desired tokenB amount (slippage control)
    }

    struct RepayAmounts {
        uint amtLPTake; // Take out LP token amount (from Homora)
        uint amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint amtARepay; // Repay tokenA amount
        uint amtBRepay; // Repay tokenB amount
        uint amtLPRepay; // Repay LP token amount
        uint amtAMin; // Desired tokenA amount
        uint amtBMin; // Desired tokenB amount
    }

    constructor(
        address _homoraBank,
        address _sushiSwapSpell,
        address _uniswapV2Spell
    ) public {
        homoraBank = _homoraBank;
        sushiSwapSpell = _sushiSwapSpell;
        uniswapV2Spell = _uniswapV2Spell;
    }

    // *** Sushiswap *** //
    // Open a position on SushiSwap thru Homora
    // 
    // Position ID is 0 for new positions, non 0 for increase in an existing position
    function openOrIncreasePositionSushiswap (
        uint256 positionID,
        address token0,
        address token1,
        uint256 supplyToken0,
        uint256 supplyToken1,
        uint256 supplyLp,
        uint256 borrowToken0,
        uint256 borrowToken1,
        uint256 pid // pool id
    ) external returns (uint) {
        if (supplyToken0 > 0) {
            IERC20(token0).approve(homoraBank, supplyToken0);
            IERC20(token0).transferFrom(msg.sender, address(this), supplyToken0);
        }
        if (supplyToken1 > 0) {
            IERC20(token1).approve(homoraBank, supplyToken1);
            IERC20(token1).transferFrom(msg.sender, address(this), supplyToken1);
        }


        Amounts memory amtData = Amounts(
        // uint amtAUser; // Supplied tokenA amount
        // uint amtBUser; // Supplied tokenB amount
        // uint amtLPUser; // Supplied LP token amount
        // uint amtABorrow; // Borrow tokenA amount
        // uint amtBBorrow; // Borrow tokenB amount
        // uint amtLPBorrow; // Borrow LP token amount
        // uint amtAMin; // Desired tokenA amount (slippage control)
        // uint amtBMin; // Desired tokenB amount (slippage control)
            supplyToken0,
            supplyToken1,
            supplyLp,
            borrowToken0,
            borrowToken1,
            0, // No LP borrow
            0, // Token 0 and 1 mins are 0
            0
        ); 

        uint positionID = IHomoraBank(homoraBank).execute(
            positionID, // New positions always have id of 0
            sushiSwapSpell, 
            abi.encodeWithSelector( // Encode the ABI header
                //bytes4(keccak256(bytes('addLiquidityWMasterChef(address,address,Amounts,uint)'))), 
                IHomoraSushiSpell.addLiquidityWMasterChef.selector,
                token0,
                token1,
                amtData,
                pid
            ) 
        );
        return positionID;
    }

    function reducePositionSushiswap (
        uint256 positionID,
        address token0,
        address token1,
        uint256 amtLPTake,
        uint256 amtLPWithdraw,
        uint256 repayAmtToken0,
        uint256 repayAmtToken1
    ) external {

        RepayAmounts memory amtData = RepayAmounts(
            amtLPTake,
            amtLPWithdraw,
            repayAmtToken0,
            repayAmtToken1,
            0, // No repay of LP
            0, // Token 0 and 1 mins are 0
            0
        );

        IHomoraBank(homoraBank).execute(
            positionID,
            sushiSwapSpell, 
            abi.encodeWithSelector( // Encode the ABI header
                //bytes4(keccak256(bytes('removeLiquidityWMasterChef(address,address,RepayAmounts)'))), 
                IHomoraSushiSpell.removeLiquidityWMasterChef.selector,
                token0,
                token1,
                amtData
            ) 
        );   
    }

    // Sushiswap harvest rewards
    function harvestSushiswap(
        uint256 positionID
    ) external {
        IHomoraBank(homoraBank).execute(
            positionID,
            sushiSwapSpell, 
            abi.encodeWithSelector( // Encode the ABI header
                IHomoraSushiSpell.harvestWMasterChef.selector
            ) 
        );   
    }

    // Sushiswap get pending rewards
    function getPendingRewardForSushiswap(uint256 _positionId) external view returns (uint) {
        (address owner, address collToken, uint collId, uint collateralSize) = getPositionInfo(_positionId);
        IWMasterChef chef = IHomoraSushiSpell(sushiSwapSpell).wmasterchef();
        (uint decodedPid, uint startTokenPerShare) = chef.decodeId(collId);
        (address lpToken, uint allocPoint, uint lastRewardBlock, uint accSushiPerShare) = chef.chef().poolInfo(decodedPid);
        uint rewardShare = accSushiPerShare - startTokenPerShare;
        return DopeAssMathLib.mulWad(rewardShare, collateralSize);
    }

  /// @dev Return position information for the given position id.
  /// @param positionId The position id to query for position information.
  function getPositionInfo(uint positionId) public view returns ( address owner, address collToken, uint collId, uint collateralSize) {
    return IHomoraBank(homoraBank).getPositionInfo(positionId);
  }

  /// @dev Return the list of all debts for the given position id.
  /// @param positionId position id to get debts of
  function getPositionDebts(uint positionId) external view returns (address[] memory tokens, uint[] memory debts) {
    return IHomoraBank(homoraBank).getPositionDebts(positionId);
  }

  /// @dev Return the debt share of the given bank token for the given position id.
  /// @param positionId position id to get debt of
  /// @param token ERC20 debt token to query
  function getPositionDebtShareOf(uint positionId, address token) external view returns (uint) {
    return IHomoraBank(homoraBank).getPositionDebtShareOf(positionId, token);
  }

  /// @dev Return bank information for the given token.
  /// @param token The token address to query for bank information.
  function getBankInfo(address token) external view returns (bool isListed, address cToken, uint reserve, uint totalDebt, uint totalShare) {
    return IHomoraBank(homoraBank).getBankInfo(token);
  }
  
  /// @dev Check whether the oracle supports the token
  /// @param token ERC-20 token to check for support
  function support(address token) external view returns (bool) {
    return IHomoraBank(homoraBank).support(token);
  }

  /// @dev Return the borrow balance for given position and token without triggering interest accrual.
  /// @param positionId The position to query for borrow balance.
  /// @param token The token to query for borrow balance.
  function borrowBalanceStored(uint positionId, address token) external view returns (uint) {
    return IHomoraBank(homoraBank).borrowBalanceStored(positionId, token);
  }

  /// @dev Return the total collateral value of the given position in ETH.
  /// @param positionId The position ID to query for the collateral value.
  function getCollateralETHValue(uint positionId) external view returns (uint) {
    return IHomoraBank(homoraBank).getCollateralETHValue(positionId);
  }

  /// @dev Return the total borrow value of the given position in ETH.
  /// @param positionId The position ID to query for the borrow value.
  function getBorrowETHValue(uint positionId) external view returns (uint) {
    return IHomoraBank(homoraBank).getBorrowETHValue(positionId);
  }
}

