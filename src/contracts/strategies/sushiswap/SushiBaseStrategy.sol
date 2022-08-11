// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseStrategy, StrategyParams} from "../../yearn/BaseStrategy.sol";
import { IMasterChef }                from "../../../interfaces/sushiswap/IMasterChef.sol";
import { IERC20 }                     from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 }                  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapRouter }             from "../../../interfaces/uniswap/IUniswapRouter.sol";
import { IUniswapV2Pair }             from "../../../interfaces/uniswap/IUniswapPair.sol";

/// @notice This is a base strategy for the SushiSwap
/// @author Khanh 
contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /// Constant variables for LP management
    /// @dev V1 - Can it be internal?
    IERC20 public constant reward = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); //The token we farm(Sushi)
    IMasterChef public constant MASTERCHEF = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IUniswapRouter public constant ROUTER = IUniswapRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SwapRouter Address

    /// @dev id of the staking pool
    uint256 internal immutable pid; // Pool ID
    /// @dev staking LP token's addresses
    address internal immutable token0; // token0 for want(LP) token
    address internal immutable token1; // token1 for want(LP) token
    ///@dev could be want token, or LP token to be used for sushi masterchef
    address internal immutable pair;

    //////////////////////////////////////////////////////////////////////
    // CONSTRUCTION
    //////////////////////////////////////////////////////////////////////
    constructor(
        address _vault,
        address _token0,
        address _token1,
        uint256 _pid
    ) BaseStrategy(_vault) {
        token0     = _token0;
        token1     = _token1;
        pid        = _pid;
        (pair, , , )    = MASTERCHEF.poolInfo(_pid);
    }

    function name() external pure virtual override returns (string memory) {
        return "StrategySushiGeneric";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        (uint256 staked, ) = MASTERCHEF.userInfo(pid, address(this));
        return want.balanceOf(address(this)) + staked;
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        /// @dev harvest sushi token
        MASTERCHEF.withdraw(pid, 0);

        uint256 toSwap = reward.balanceOf(address(this));

        uint256 profit = _swapToWant(toSwap);

        // Deal with debt
        if (profit > _debtOutstanding) {
            _debtPayment = _debtOutstanding;
        } else {
            _debtPayment = profit;
        }
        _loss = 0; // Can't loose funds, unless rugged

        _profit = profit - _debtPayment;
    }

    /// @dev deposit _debtOutstanding amount to masterchef
    function adjustPosition(uint256 _debtOutstanding) internal virtual override {
        uint256 _preWant = want.balanceOf(address(this));
        if (_preWant > _debtOutstanding) {
            uint256 toDeposit = _preWant - _debtOutstanding;

            want.approve(address(MASTERCHEF), toDeposit);
            MASTERCHEF.deposit(pid, toDeposit);
        }
    }

    /// @notice same as adjustPosition
    function addToPosition(uint256 _debtOutstanding) internal virtual override {
        adjustPosition(_debtOutstanding);
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 _preWant = want.balanceOf(address(this));

        // If we lack sufficient idle want, withdraw the difference from the strategy position
        if (_preWant < _amountNeeded) {
            uint256 _toWithdraw = _amountNeeded - _preWant;
            MASTERCHEF.withdraw(pid, _toWithdraw);

            // Note: Withdrawl process will earn rewards, this will be deposited into SushiBar on next adjustPositions()
        }

        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            _loss = _amountNeeded - totalAssets;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal virtual override returns (uint256) {
        (uint256 staked, ) = MASTERCHEF.userInfo(pid, address(this));

        // Withdraw all want from Chef
        MASTERCHEF.withdrawAndHarvest(pid, staked, address(this));

        return want.balanceOf(address(this));
    }

    function prepareMigration(address _newStrategy) internal virtual override {
        liquidateAllPositions();
    }
    /// @notice Protect tokens from sweeping
    /// @return Array of the protected tokens
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        // NOTE: May need to add lpComponent anyway
        address[] memory protected = new address[](2);
        protected[0] = address(reward);
        protected[1] = address(want);
        return protected;
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // TODO create an accurate price oracle
        return _amtInWei;
    }

    function _swapToWant(uint256 toSwap) internal returns (uint256) {
        uint256 startingWantBalance = want.balanceOf(address(this));
        if (toSwap == 0)
            return 0;

        /// @dev swap half sushi token to WETH
        address[] memory path = new address[](2);
        path[0] = address(reward);
        path[1] = token0;

        reward.approve(address(ROUTER), toSwap);
        /// @dev slippage check
        uint256[] memory token0AmountOuts = ROUTER.swapExactTokensForTokens(toSwap/2, 0, path, address(this), block.timestamp);

        /// @dev swap half sushi token to SYN
        path[0] = address(reward);
        path[1] = token1;

        /// @dev slippage check
        uint256[] memory token1AmountOuts = ROUTER.swapExactTokensForTokens(toSwap/2, 0, path, address(this), block.timestamp);

        /// @dev add liquidity to sushiswap
        IERC20(token0).safeTransfer(pair, token0AmountOuts[token0AmountOuts.length - 1]);
        IERC20(token1).safeTransfer(pair, token1AmountOuts[token1AmountOuts.length - 1]);
        IUniswapV2Pair(pair).mint(address(this));

        return want.balanceOf(address(this)) - startingWantBalance;
    }
}