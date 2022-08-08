// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

interface ISwapperImpl {
    function tokenIn() external view returns (address);

    function tokenOut() external view returns (address);

    function swap(uint256 _amountIn, address _to)
        external
        returns (uint256 amountOut);
}
