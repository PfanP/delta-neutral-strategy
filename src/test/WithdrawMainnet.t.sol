// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "../../lib/forge-std/src/console.sol";

//import {StrategyParams} from "../interfaces/IVault.sol";

import {Strategy} from "../contracts/Strategy.sol";
import {ExtendedTest} from "./utils/ExtendedTest.sol";
import {IVault} from "../interfaces/IVault.sol";
import "../../utils/VyperDeployer.sol";
import {VyperTest} from "../../utils/VyperTest.sol";
import "../Token.sol";
import {IHomoraBank} from "../interfaces/IHomoraBank.sol";

contract WithdrawTest is ExtendedTest, VyperTest {
    Strategy DNStrategy;
    Token vaultToken;
    ConcaveOracle concaveOracle;

    address gov = 0xe142BAe2338D2c691C267B054b13d38Ce6aC5442;
    address rewards = 0x0000000000000000000000000000000000000100; // Any wallet will do

    address sushiSwapSpell = 0xA2caEa05fF7B98f10Ad5ddc837F15905f33FEb60; // https://etherscan.io/address/0xDc9c7A2Bae15dD89271ae5701a6f4DB147BAa44C
    address router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // SushiSwap router

    address token0 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI on ETH
    address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH on ETH
    uint farmLeverage = 3;
    address lpToken = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f; // DAI<>WETh LP on SushiSwap

    address keeper = 0x0000000000000000000000000000000000000003; // Our Bot keeper address

    function setUp() public {
        vaultToken = new Token();
        concaveOracle = new ConcaveOracle();

        address hBankAddress = 0xba5eBAf3fc1Fcca67147050Bf80462393814E54B;
        IHomoraBank hBank = IHomoraBank(hBankAddress);

        string memory vaultArtifact = "artifacts/Vault.json";
        address _vaultAddress = deployCode(vaultArtifact);
        //VyperDeployer vyperDeployer = new VyperDeployer();
        IVault vault = IVault(
            //vyperDeployer.deployContract("Vault", abi.encode())
            _vaultAddress
            // deployContract("vyper_contracts/Vault.vy")
        );

        string memory _name = 'CVault';
        string memory _symbol = 'vCNV';
        vault.initialize(
            address(vaultToken),
            address(this),
            rewards,
            _name,
            _symbol//,
            //_guardian,
            //_management
        );
        vm.prank(gov);
        vault.setDepositLimit(90000e18);

        
        DNStrategy = new Strategy(
            address(vault),
            hBankAddress,
            sushiSwapSpell,
            router,
            token0,
            token1,
            farmLeverage,
            address(concaveOracle),
            lpToken
        );

        vault.addStrategy(
            address(DNStrategy), 
            10000, // debtRatio
            0, // _minDebtPerHarvest 
            0, // _maxDebtPerHarvest 
            0  // performanceFee
        );

        address[] memory users = new address[](1);
        users[0] = address(DNStrategy);

        bool[] memory userStatus = new bool[](users.length);
        for (uint i = 0; i < users.length; i++) {
            userStatus[i] = true;
        }

        vm.prank(gov);
        hBank.setWhitelistUsers(users, userStatus);

    }

    uint _longPositionId = 1;
    uint _shortPositionId = 2;

    uint _mockHarvestAmount = 0;
    uint _longPositionEquityETH = 2e18;
    uint _longPositionLoanETH = 3e18;
    uint _shortPositionEquityETH = 8e17;
    uint _shortPositionLoanETH = 3e18; 
    uint _longLPAmount = 2e18;
    uint _shortLPAmount = 2e18;

    uint _longPositionDebtToken0 = 20e18;
    uint _shortPositionDebtToken1 = 3e18;

    function test_openPosition() public {
        
    }


    function test_tend() public {
        DNStrategy.setShortPositionId(_shortPositionId);
        DNStrategy.setLongPositionId(_longPositionId);

        // Test the Override Mode
        //DNStrategy.tend(true);
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



contract ConcaveOracle {
    function getETHPx(address token) external view returns (uint256) {
        return 1000;
    }

    function getPrice(address token0, address tokenUnit)
        external
        view
        returns (uint256, uint256)
    {
        return (1000, 1000);
    }

    function support(address token) external view returns (bool) {
        return true;
    }
}