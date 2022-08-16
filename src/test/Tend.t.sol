// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "../../lib/forge-std/src/console.sol";

//import {StrategyParams} from "../interfaces/IVault.sol";

import {Strategy} from "../contracts/Strategy.sol";
import {ExtendedTest} from "./utils/ExtendedTest.sol";
import {IVault} from "../interfaces/IVault.sol";

contract TendTest is ExtendedTest {
    address vaultToken = 0x0000000000000000000000000000000000000000;
    address gov = 0x0000000000000000000000000000000000000000;
    address rewards = 0x0000000000000000000000000000000000000000;

    address hBank = 0x0000000000000000000000000000000000000000;
    address sushiSwapSpell = 0x0000000000000000000000000000000000000000;
    address swapper = 0x0000000000000000000000000000000000000000;

    address token0 = 0x0000000000000000000000000000000000000001;
    address token1 = 0x0000000000000000000000000000000000000002;
    uint farmLeverage = 3;
    address concaveOracle = 0x0000000000000000000000000000000000000000;
    address lpToken = 0x0000000000000000000000000000000000000000;

    function setUp() public {
        string memory vaultArtifact = "artifacts/Vault.json";
        address _vaultAddress = deployCode(vaultArtifact);
        //VyperDeployer vyperDeployer = new VyperDeployer();
        IVault vault = IVault(
            //vyperDeployer.deployContract("Vault", abi.encode())
            _vaultAddress
        );

        string memory _name = 'CVault';
        string memory _symbol = 'vCNV';
        vault.initialize(
            vaultToken,
            gov,
            rewards,
            _name,
            _symbol//,
            //_guardian,
            //_management
        );

        Strategy strategy = new Strategy(
            address(vault),
            hBank,
            sushiSwapSpell,
            swapper,
            token0,
            token1,
            farmLeverage,
            concaveOracle,
            lpToken
        );



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
