// SPDX-License-Identifier: MIT
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.0;
import {BaseStrategy, StrategyParams} from "../../yearn/BaseStrategy.sol";
import { IMasterChef } from "../../../interfaces/sushiswap/IMasterChef.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapRouter } from "../../../interfaces/uniswap/IUniswapRouter.sol";

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;

    IERC20 public reward; //The token we farm(Sushi)
    uint256 public pid; // Pool ID

    address public WETH; // weth address to swap

    IMasterChef public MASTERCHEF; // Address of Sushi Staking Contract

    IUniswapRouter public ROUTER; // SwapRouter Address

    constructor(
        address _vault,
        IERC20 _reward,
        uint256 _pid,
        address _WETH,
        IMasterChef _MASTERCHEF,
        IUniswapRouter _ROUTER
    ) public BaseStrategy(_vault) {
        reward = _reward;
        pid = _pid;
        WETH = _WETH;
        MASTERCHEF = _MASTERCHEF;
        ROUTER = _ROUTER;
    }

    function name() external view override returns (string memory) {
        return "StrategySushiGeneric";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        (uint256 staked, ) = MASTERCHEF.userInfo(pid, address(this));
        return want.balanceOf(address(this)) + staked;
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        MASTERCHEF.harvest(pid, address(this));

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

    function adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 _preWant = want.balanceOf(address(this));
        if (_preWant > _debtOutstanding) {
            uint256 toDeposit = _preWant - _debtOutstanding;

            want.approve(address(MASTERCHEF), toDeposit);
            MASTERCHEF.deposit(pid, toDeposit);
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
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

    function liquidateAllPositions() internal override returns (uint256) {
        (uint256 staked, ) = MASTERCHEF.userInfo(pid, address(this));

        // Withdraw all want from Chef
        MASTERCHEF.withdrawAndHarvest(pid, staked, address(this));

        return want.balanceOf(address(this));
    }

    function prepareMigration(address _newStrategy) internal override {
        liquidateAllPositions();
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
        // NOTE: May need to add lpComponent anyway
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

        address[] memory path = new address[](3);
        path[0] = address(reward);
        path[1] = WETH;
        path[2] = address(want);

        reward.approve(address(ROUTER), toSwap);

        /// @dev slippage check
        ROUTER.swapExactTokensForTokens(toSwap, 0, path, address(this), block.timestamp);

        return want.balanceOf(address(this)) - startingWantBalance;
    }
}