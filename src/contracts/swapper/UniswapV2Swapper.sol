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

    constructor(address _uniswapV2Router) {
        uniswapV2Router = _uniswapV2Router;
    }

    function swap(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        address _to
    ) external override returns (uint256 amountOut) {
        require(_tokenIn != _tokenOut, "invalid token");

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).safeApprove(uniswapV2Router, _amountIn);

        uint256[] memory amountsOut = IUniswapRouter(uniswapV2Router)
            .swapExactTokensForTokens(_amountIn, 0, path, _to, block.timestamp);

        return amountsOut[amountsOut.length - 1];
    }

    function swap(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        address[] memory _path,
        address _to
    ) external override returns (uint256 amountOut) {
        require(_tokenIn != _tokenOut, "invalid token");
        require(
            _path[0] == _tokenIn && _path[_path.length - 1] == _tokenOut,
            "invalid path"
        );

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).safeApprove(uniswapV2Router, _amountIn);

        uint256[] memory amountsOut = IUniswapRouter(uniswapV2Router)
            .swapExactTokensForTokens(
                _amountIn,
                0,
                _path,
                _to,
                block.timestamp
            );

        return amountsOut[amountsOut.length - 1];
    }
}
