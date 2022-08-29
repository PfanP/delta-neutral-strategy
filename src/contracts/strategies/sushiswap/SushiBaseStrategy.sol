// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseStrategy, StrategyParams} from "../../yearn/BaseStrategy.sol";
import { IMasterChef }                from "../../../interfaces/sushiswap/IMasterChef.sol";
import { IERC20 }                     from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math }                       from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeERC20 }                  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapRouter }             from "../../../interfaces/uniswap/IUniswapRouter.sol";
import { IUniswapV2Pair }             from "../../../interfaces/uniswap/IUniswapPair.sol";

/// @notice This is a base strategy for the SushiSwap
/// @dev LP token farming contract
/// @author Khanh 
contract SushiBaseStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    /// Constant variables for LP management
    /// @dev V1 - Can it be internal?
    IERC20 public constant reward = IERC20(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a); //The token we farm(Sushi)
    IMasterChef public constant MASTERCHEF = IMasterChef(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    IUniswapRouter public constant ROUTER = IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // SwapRouter Address

    /// @dev id of the staking pool
    uint256 internal immutable pid; // Pool ID
    /// @dev staking LP token's addresses
    address internal immutable token0; // token0 for want(LP) token
    address internal immutable token1; // token1 for want(LP) token
    ///@dev could be want token, or LP token to be used for sushi masterchef
    event Test(uint);
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

        // You can set these parameters on deployment to whatever you want
        maxReportDelay = 6300;
        profitFactor = 1500;
        debtThreshold = 1_000_000 * 1e18;

        /// @dev: original code
        // (address poolToken, , , ) = MASTERCHEF.poolInfo(pid);
        address poolToken = MASTERCHEF.lpToken(pid);
        want = IERC20(poolToken);

        want.safeApprove(address(MASTERCHEF), type(uint256).max);
        IERC20(reward).safeApprove(address(ROUTER), type(uint256).max);
    }


    function name() external pure virtual override returns (string memory) {
        return "StrategySushiMasterChefGeneric";
    }

    function delegatedAssets() external view override returns (uint256) {
        return 0;
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
        // Depends on wut token we use as underlying
        return _amtInWei;
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
        MASTERCHEF.withdraw(pid, 0, address(this));

        uint256 assets = estimatedTotalAssets();
        uint256 toSwap = reward.balanceOf(address(this));

        uint256 profit = _swapToWant(toSwap);
        uint256 debt = vault.strategies(address(this)).totalDebt;
        uint256 wantBal = want.balanceOf(address(this));
    
        if (assets > debt) {
            _debtPayment = _debtOutstanding;
            _profit = assets - debt;

            uint256 amountToFree = _profit + _debtPayment;

            if (amountToFree > 0 && wantBal < amountToFree) {
                liquidatePosition(amountToFree);

                uint256 newLoose = want.balanceOf(address(this));

                //if we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(
                            newLoose - _profit,
                            _debtPayment
                        );
                    }
                }
            }
        } else {
            //serious loss should never happen but if it does lets record it accurately
            _loss = debt - assets;
        }
    }

    /// @dev deposit _debtOutstanding amount to masterchef
    function adjustPosition(uint256 _debtOutstanding) internal virtual override {
        uint256 _preWant = want.balanceOf(address(this));
        if (_preWant > _debtOutstanding) {
            uint256 toDeposit = _preWant - _debtOutstanding;
            emit Test(_preWant);
            MASTERCHEF.deposit(pid, toDeposit, address(this));
        }
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
            (uint256 deposited, ) =
                MASTERCHEF.userInfo(pid, address(this));

            if (deposited < _toWithdraw) {
                _toWithdraw = deposited;
            }

            if (deposited > 0) {
                MASTERCHEF.withdraw(pid, _toWithdraw, address(this));
            }
            // Note: Withdrawl process will earn rewards, this will be deposited into SushiBar on next adjustPositions()
            _liquidatedAmount = want.balanceOf(address(this));
            _loss = _amountNeeded - _liquidatedAmount;
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

    function tendTrigger(uint256 callCostInWei) public view override returns (bool) {
        return false;
    }

    function tend(bool _overrideMode) external override onlyKeepers {
        adjustPosition(0);
    }

    function prepareRebalance(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        ) {

    }

    function harvestTrigger(uint256 callCostInWei) public view override returns (bool) {
        return false;
    }


    function prepareMigration(address _newStrategy) internal virtual override {
        liquidateAllPositions();
        uint256 toSwap = reward.balanceOf(address(this));
        _swapToWant(toSwap);
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
        IERC20(token0).safeTransfer(address(want), token0AmountOuts[token0AmountOuts.length - 1]);
        IERC20(token1).safeTransfer(address(want), token1AmountOuts[token1AmountOuts.length - 1]);
        IUniswapV2Pair(address(want)).mint(address(this));

        return want.balanceOf(address(this)) - startingWantBalance;
    }
}