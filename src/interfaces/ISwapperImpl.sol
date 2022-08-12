// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

interface ISwapperImpl {
    function swap(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        address _to
    ) external returns (uint256 amountOut);

    function swap(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        address[] memory _path,
        address _to
    ) external returns (uint256 amountOut);
}
