// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for Alpha Homora Leveraged Yield Farms
/// @notice Operates positons on Homora farms
interface IHomoraFarmHandler {
    /// @notice
    /// @param
    function openOrIncreasePositionSushiswap(
        uint256 positionID,
        address token0,
        address token1,
        uint256 supplyToken0,
        uint256 supplyToken1,
        uint256 supplyLp,
        uint256 borrowToken0,
        uint256 borrowToken1,
        uint256 pid
    ) external;

    function harvestSushiswap(uint256 positionId) external;

    /// @dev Return position information for the given position id.
    /// @param positionId The position id to query for position information.
    function getPositionInfo(uint256 positionId)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    /// @dev Return the list of all debts for the given position id.
    /// @param positionId position id to get debts of
    function getPositionDebts(uint256 positionId)
        external
        view
        returns (address[] memory tokens, uint256[] memory debts);

    /// @dev Return the debt share of the given bank token for the given position id.
    /// @param positionId position id to get debt of
    /// @param token ERC20 debt token to query
    function getPositionDebtShareOf(uint256 positionId, address token)
        external
        view
        returns (uint256);

    /// @dev Return bank information for the given token.
    /// @param token The token address to query for bank information.
    function getBankInfo(address token)
        external
        view
        returns (
            bool isListed,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        );

    /// @dev Check whether the oracle supports the token
    /// @param token ERC-20 token to check for support
    function support(address token) external view returns (bool);

    /// @dev Return the borrow balance for given position and token without triggering interest accrual.
    /// @param positionId The position to query for borrow balance.
    /// @param token The token to query for borrow balance.
    function borrowBalanceStored(uint256 positionId, address token)
        external
        view
        returns (uint256);

    // Sushiswap get pending rewards
    function getPendingRewardForSushiswap(uint256 _positionId)
        external
        view
        returns (uint256);
    
    /// @dev Return the total collateral value of the given position in ETH.
    /// @param positionId The position ID to query for the collateral value.
    function getCollateralETHValue(uint positionId) external view returns (uint);

    /// @dev Return the total borrow value of the given position in ETH.
    /// @param positionId The position ID to query for the borrow value.
    function getBorrowETHValue(uint positionId) external view returns (uint);
}
