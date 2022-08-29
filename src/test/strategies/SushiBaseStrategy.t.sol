// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strategy } from "../../contracts/strategies/sushiswap/SushiBaseStrategy.sol";
import { MockERC20 } from "../mock/Tokens.sol";
import { VyperDeployer } from "../../../utils/VyperDeployer.sol";
import { ExtendedTest } from "../utils/ExtendedTest.sol";
import { IVault } from "../../interfaces/IVault.sol";

/// @dev SYN/ETH Sushi LP farming test
/// TODO: check deposit, harvest, withdraw, autocompound feature
/// NOTE: this is for testing env
/// SYN-WETH LP: 0x4A86C01d67965f8cB3d0AAA2c655705E64097C31
/// SYN-WETH Pool ID: 305
/// Sushi Masterchef: 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd
/// Sushiswap router: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
string constant vaultArtifact = "artifacts/Vault.json";
uint256 constant PID = 0;

contract SushiBaseStrategyTest is ExtendedTest {
    VyperDeployer vyperDeployer = new VyperDeployer();
    address synLP = 0xc4e595acDD7d12feC385E5dA5D43160e8A0bAC0E;
    address sushi = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address weth  = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address syn   = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address masterChef = address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    address router = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address wethWhale = address(0xC9CbB5B3eA986375E28dD0e8E129179f643b8D7B);
    Strategy sushiStrategy;

    using SafeERC20 for IERC20;

    IVault public vault;
    Strategy public strategy;
    IERC20 public want = IERC20(synLP);

    address public gov = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;

    address public whale = address(2);
    address public rewards = address(3);
    address public guardian = address(4);
    address public management = address(5);
    address public strategist = address(6);
    address public keeper = address(7);

    uint256 public minFuzzAmt;
    // @dev maximum amount of want tokens deposited based on @maxDollarNotional
    uint256 public maxFuzzAmt;
    // @dev maximum dollar amount of tokens to be deposited
    uint256 public maxDollarNotional = 1_000_000;
    // @dev maximum dollar amount of tokens for single large amount
    uint256 public bigDollarNotional = 49_000_000;
    // @dev used for non-fuzz tests to test large amounts
    uint256 public bigAmount;
    // Used for integer approximation
    uint256 public constant DELTA = 10**5;

    function setUp() public virtual {
        // Choose a token from the tokenAddrs mapping, see _setTokenAddrs for options

        (address _vault, address _strategy) = deployVaultAndStrategy(
            address(synLP),
            gov,
            sushi,
            "",
            "",
            guardian,
            management,
            keeper,
            strategist
        );
        vault = IVault(_vault);
        strategy = Strategy(_strategy);

        // add more labels to make your traces readable
        vm.label(address(vault), "Vault");
        vm.label(address(strategy), "Strategy");
        vm.label(address(want), "Want");
        vm.label(gov, "Gov");
        vm.label(whale, "Whale");
        vm.label(rewards, "Rewards");
        vm.label(guardian, "Guardian");
        vm.label(management, "Management");
        vm.label(strategist, "Strategist");
        vm.label(keeper, "Keeper");
        vm.label(masterChef, "MasterChef");
        vm.label(synLP, "SYN-LP");

        // do here additional setup
    }

    // Deploys a vault
    function deployVault(
        address _token,
        address _gov,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management
    ) public returns (address) {
        address _vaultAddress = deployCode(vaultArtifact);
        IVault _vault = IVault(_vaultAddress);

        vm.prank(_gov);
        _vault.initialize(
            _token,
            _gov,
            _rewards,
            _name,
            _symbol,
            _guardian,
            _management
        );

        vm.prank(_gov);
        _vault.setDepositLimit(type(uint256).max);

        return address(_vault);
    }

    // Deploys a strategy
    function deployStrategy(
        address _vault,
        uint256 _pid,
        address _token0,
        address _token1
    ) public returns (address) {
        Strategy _strategy = new Strategy(_vault, _token0, _token1, _pid);
        return address(_strategy);
    }

    // Deploys a vault and strategy attached to vault
    function deployVaultAndStrategy(
        address _token,
        address _gov,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management,
        address _keeper,
        address _strategist
    ) public returns (address _vaultAddr, address _strategyAddr) {
        _vaultAddr = deployVault(
            _token,
            _gov,
            _rewards,
            _name,
            _symbol,
            _guardian,
            _management
        );
        IVault _vault = IVault(_vaultAddr);
        
        vm.prank(_strategist);
        _strategyAddr = deployStrategy(
            _vaultAddr,
            PID,
            weth,
            syn
        );
        Strategy _strategy = Strategy(_strategyAddr);

        vm.prank(_strategist);
        _strategy.setKeeper(_keeper);

        vm.prank(_gov);
        _vault.addStrategy(_strategyAddr, 10_000, 0, type(uint256).max, 1_000);

        return (address(_vault), address(_strategy));
    }

    function test_setupVaultOK() public {
        console.log("address of vault", address(vault));
        assertTrue(address(0) != address(vault));
        assertEq(vault.token(), address(want));
        assertEq(vault.depositLimit(), type(uint256).max);
    }

    // TODO: add additional check on strat params
    function test_setupStrategyOK() public {
        console.log("address of strategy", address(strategy));
        assertTrue(address(0) != address(strategy));
        assertEq(address(strategy.vault()), address(vault));
    }

    /// Test Operations
    function test_StrategyOperation() public {
        uint _amount = 1e18;
        // deal(address(want), wethWhale, _amount);

        uint256 balanceBefore = want.balanceOf(address(wethWhale));
        vm.prank(wethWhale);
        want.approve(address(vault), _amount);
        vm.prank(wethWhale);
        vault.deposit(_amount);
        assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

        skip(3 minutes);
        vm.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        // tend
        vm.prank(strategist);
        strategy.tend(false);

        vm.prank(wethWhale);
        vault.withdraw();
        // assertRelApproxEq(want.balanceOf(wethWhale), balanceBefore, DELTA);
    }
}