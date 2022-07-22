// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for Alpha Homora Leveraged Yield Farms
/// @notice Operates positons on Homora farms
interface IHomoraFarmHandler {
    /// @notice
    /// @param 
    function openOrIncreasePositionSushiswap(uint256 positionID, address token0, address token1, uint256 supplyToken0, uint256 supplyToken1, uint256 supplyLp, uint256 borrowToken0, uint256 borrowToken1, uint256 pid) external;
    
}