// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IERC20Wrapper} from './IERC20Wrapper.sol';
import {IMasterChef} from './IMasterChef.sol';

// Info of each pool.
struct PoolInfo {
  IERC20 lpToken; // Address of LP token contract.
  uint allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
  uint lastRewardBlock; // Last block number that SUSHIs distribution occurs.
  uint accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
}

interface IWMasterChef is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(uint pid, uint amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint pid);

  function sushi() external returns (IERC20);

  function decodeId(uint id) external pure returns (uint, uint);

  function chef() external view returns (IMasterChef);
}
