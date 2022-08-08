// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ISwapperImpl.sol";
import "../../interfaces/uniswap/IUniswapRouter.sol";

contract UniswapV2Swapper is ISwapperImpl {
    using SafeERC20 for IERC20;

    address public uniswapV2Router;
    address public override tokenIn;
    address public override tokenOut;
    address[] public path;

    constructor(
        address _uniswapV2Router,
        address _tokenIn,
        address _tokenOut,
        address[] memory _path
    ) {
        require(_tokenIn != _tokenOut, "invalid token");
        require(
            _path[0] == _tokenIn && _path[_path.length - 1] == _tokenOut,
            "invalid path"
        );

        uniswapV2Router = _uniswapV2Router;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        path = _path;
    }

    function swap(uint256 _amountIn, address _to)
        external
        override
        returns (uint256 amountOut)
    {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(tokenIn).safeApprove(uniswapV2Router, _amountIn);

        uint256[] memory amountsOut = IUniswapRouter(uniswapV2Router)
            .swapExactTokensForTokens(_amountIn, 0, path, _to, block.timestamp);

        return amountsOut[amountsOut.length - 1];
    }
}
