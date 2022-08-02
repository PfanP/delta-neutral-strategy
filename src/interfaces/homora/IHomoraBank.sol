// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// @title The interface for Alpha Homora Leveraged Yield Farms
/// @notice Operates positons on Homora farms
interface IHomoraBank {

  /// @dev Execute the action via HomoraCaster, calling its function with the supplied data.
  /// @param positionId The position ID to execute the action, or zero for new position.
  /// @param spell The target spell to invoke the execution via HomoraCaster.
  /// @param data Extra data to pass to the target for the execution.
  function execute(uint positionId, address spell, bytes memory data) external payable returns (uint);


  //////////View Functions//////////

  /// @dev Return position information for the given position id.
  /// @param positionId The position id to query for position information.
  function getPositionInfo(uint positionId) external view returns ( address owner, address collToken, uint collId, uint collateralSize);

  /// @dev Return the list of all debts for the given position id.
  /// @param positionId position id to get debts of
  function getPositionDebts(uint positionId) external view returns (address[] memory tokens, uint[] memory debts);

  /// @dev Return the debt share of the given bank token for the given position id.
  /// @param positionId position id to get debt of
  /// @param token ERC20 debt token to query
  function getPositionDebtShareOf(uint positionId, address token) external view returns (uint);

  /// @dev Return bank information for the given token.
  /// @param token The token address to query for bank information.
  function getBankInfo(address token) external view returns (bool isListed, address cToken, uint reserve, uint totalDebt, uint totalShare);
  
  /// @dev Check whether the oracle supports the token
  /// @param token ERC-20 token to check for support
  function support(address token) external view returns (bool);

  /// @dev Return the borrow balance for given position and token without triggering interest accrual.
  /// @param positionId The position to query for borrow balance.
  /// @param token The token to query for borrow balance.
  function borrowBalanceStored(uint positionId, address token) external view returns (uint);

  /// @dev Return the total collateral value of the given position in ETH.
  /// @param positionId The position ID to query for the collateral value.
  function getCollateralETHValue(uint positionId) external view returns (uint);

  /// @dev Return the total borrow value of the given position in ETH.
  /// @param positionId The position ID to query for the borrow value.
  function getBorrowETHValue(uint positionId) external view returns (uint);

}
