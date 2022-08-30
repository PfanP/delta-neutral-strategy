// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "../../lib/forge-std/src/console.sol";

//import {StrategyParams} from "../interfaces/IVault.sol";

import {Strategy} from "../contracts/Strategy.sol";
import {ExtendedTest} from "./utils/ExtendedTest.sol";
import {IVault} from "../interfaces/IVault.sol";
import "../../utils/VyperDeployer.sol";
import {VyperTest} from "../../utils/VyperTest.sol";
//import "../Token.sol";
import {IHomoraBank} from "../interfaces/IHomoraBank.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {PositionSimulator} from "./PositionSimulator.t.sol";

contract WithdrawTest is ExtendedTest, VyperTest, PositionSimulator {
    uint farmLeverage = 15e17;

    function setUp() public {
        super.setUpPositionSimulator(
            farmLeverage
        );
    }

    // Test the tend function 
    function test_mainnetWithdraw() public {
        setupPosition();

        vm.prank(daiWhale);
        vault.withdraw();
/*
        uint amtLpTake = 1e16;
        uint amtLpWithdraw = 1e16;
        uint amtRepayToken0 = 0;
        uint amtRepayToken1 = 0;
        uint amountLpRepay = 0;

        removeFromDNPositions(
            positionId, 
            amtLpTake, // Convert To Units of DAI
            amtLpWithdraw,
            amtRepayToken0, // Convert To Units of DAI
            amtRepayToken1, // Convert To Units of DAI
            amountLpRepay 
        ); 
        
        emit log_uint(88888888888888);*/ 

        //DNStrategy.tend(false); 

        // Override mode could liquidate everything into LP tokens - 
        // Then, it would put them back into balanced positions
        
        // Test the Override Mode
        //DNStrategy.tend(true);
        /*
        (
            uint longLpRemove,
            uint longLpLoanPayback,
            uint shortLpRemove,
            uint shortLpLoanPayback,
            uint action3LpTokenBal,
            uint longLoanIncrase,
            uint shortLoanIncrease) = 
        DNStrategy.tend(false);
        
        emit log_uint(longLpRemove);
        */ 
    }


    function test_setupVault() public {
        emit log_address(address(vault));
    }

/*
    /// Test Operations
    function testStrategyOperation(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
        deal(address(want), user, _amount);

        uint256 balanceBefore = want.balanceOf(address(user));
        vm.prank(user);
        want.approve(address(vault), _amount);
        vm.prank(user);
        vault.deposit(_amount);
        assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

        skip(3 minutes);
        vm.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        // tend
        vm.prank(strategist);
        strategy.tend(false); // Override mode is the param

        vm.prank(user);
        vault.withdraw();

        assertRelApproxEq(want.balanceOf(user), balanceBefore, DELTA);
    }

    function testProfitableHarvest(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
        deal(address(want), user, _amount);

        // Deposit to the vault
        vm.prank(user);
        want.approve(address(vault), _amount);
        vm.prank(user);
        vault.deposit(_amount);
        assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

        uint256 beforePps = vault.pricePerShare();

        // Harvest 1: Send funds through the strategy
        skip(1);
        vm.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        // TODO: Add some code before harvest #2 to simulate earning yield

        // Harvest 2: Realize profit
        skip(1);
        vm.prank(strategist);
        strategy.harvest();
        skip(6 hours);

        // TODO: Uncomment the lines below
        // uint256 profit = want.balanceOf(address(vault));
        // assertGt(want.balanceOf(address(strategy)) + profit, _amount);
        // assertGt(vault.pricePerShare(), beforePps)
    }

    function testTriggers(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
        deal(address(want), user, _amount);

        // Deposit to the vault and harvest
        vm.prank(user);
        want.approve(address(vault), _amount);
        vm.prank(user);
        vault.deposit(_amount);
        vm.prank(gov);
        vault.updateStrategyDebtRatio(address(strategy), 5_000);
        skip(1);
        vm.prank(strategist);
        strategy.harvest();

        strategy.harvestTrigger(0);
        strategy.tendTrigger(0);
    }
*/ 
}

