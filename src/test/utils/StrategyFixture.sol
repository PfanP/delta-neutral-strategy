// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ExtendedTest} from "./ExtendedTest.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import {IVault} from "../../interfaces/IVault.sol";
import "../../../utils/VyperDeployer.sol";

// NOTE: if the name of the strat or file changes this needs to be updated
import {Strategy} from "../../contracts/Strategy.sol";
import {UniswapV2Swapper} from "../../contracts/swapper/UniswapV2Swapper.sol";

// Artifact paths for deploying from the deps folder, assumes that the command is run from
// the project root.
string constant vaultArtifact = "artifacts/Vault.json";

// Base fixture deploying Vault
contract StrategyFixture is ExtendedTest {
    using SafeERC20 for IERC20;

    IVault public vault;
    Strategy public strategy;
    IERC20 public weth;
    IERC20 public want;

    mapping(string => address) public tokenAddrs;
    mapping(string => uint256) public tokenPrices;

    // Strategy Params
    address homoraBank = 0x0000000000000000000000000000000000000000;
    address sushiSwapSpell = 0x0000000000000000000000000000000000000000;
    address token0 = 0x0000000000000000000000000000000000000000;
    address token1 = 0x0000000000000000000000000000000000000000;
    address swapper = 0x0000000000000000000000000000000000000000;
    address sushiswapRouter = 0x0000000000000000000000000000000000000000;
    uint farmLeverage = 3;
    address concaveOracle = 0x0000000000000000000000000000000000000000;
    address lpToken = 0x0000000000000000000000000000000000000000;

    address public gov = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
    address public user = address(1);
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
        _setTokenPrices();
        _setTokenAddrs();
        _setStrategyParamAddrs();

        emit log_uint(1);
        // Choose a token from the tokenAddrs mapping, see _setTokenAddrs for options
        string memory token = "DAI";
        weth = IERC20(tokenAddrs["WETH"]);
        want = IERC20(tokenAddrs[token]);
        emit log_uint(2);

        (address _vault, address _strategy) = deployVaultAndStrategy(
            address(want),
            gov,
            rewards,
            "",
            "",
            guardian,
            management,
            keeper,
            strategist
        );
        emit log_uint(3);
        vault = IVault(_vault);
        strategy = Strategy(_strategy);

        minFuzzAmt = 10**vault.decimals() / 10;
        maxFuzzAmt =
            uint256(maxDollarNotional / tokenPrices[token]) *
            10**vault.decimals();
        bigAmount =
            uint256(bigDollarNotional / tokenPrices[token]) *
            10**vault.decimals();
        emit log_uint(4);

        // add more labels to make your traces readable
        vm.label(address(vault), "Vault");
        vm.label(address(strategy), "Strategy");
        vm.label(address(want), "Want");
        vm.label(gov, "Gov");
        vm.label(user, "User");
        vm.label(whale, "Whale");
        vm.label(rewards, "Rewards");
        vm.label(guardian, "Guardian");
        vm.label(management, "Management");
        vm.label(strategist, "Strategist");
        vm.label(keeper, "Keeper");
        emit log_uint(5);

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
        //VyperDeployer vyperDeployer = new VyperDeployer();
        IVault _vault = IVault(
            //vyperDeployer.deployContract("Vault", abi.encode())
            _vaultAddress
        );
        emit log_uint(100);

        _name = 'cVault';
        _symbol = 'cv';
        emit log_address(_token);
        emit log_address(_gov);
        emit log_address(_rewards);
        emit log_string(_name);
        emit log_string(_symbol);

        //vm.prank(_gov);
        _vault.initialize(
            _token,
            _gov,
            _rewards,
            _name,
            _symbol//,
            //_guardian,
            //_management
        );

        vm.prank(_gov);
        _vault.setDepositLimit(type(uint256).max);

        return address(_vault);
    }

    // Deploys a strategy
    function deployStrategy(address _vault) public returns (address) {
        Strategy _strategy = new Strategy(
            _vault,
            homoraBank,
            sushiSwapSpell,
            swapper,
            token0,
            token1,
            farmLeverage,
            concaveOracle,
            lpToken
        );

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
        _strategyAddr = deployStrategy(_vaultAddr);
        Strategy _strategy = Strategy(_strategyAddr);

        vm.prank(_strategist);
        _strategy.setKeeper(_keeper);

        vm.prank(_gov);
        _vault.addStrategy(
            _strategyAddr, 
            10_000, 
            0, 
            type(uint256).max, 
            1_000
        );

        return (address(_vault), address(_strategy));
    }

    function _setTokenAddrs() internal {
        tokenAddrs["WBTC"] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        tokenAddrs["YFI"] = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
        tokenAddrs["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        tokenAddrs["LINK"] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        tokenAddrs["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        tokenAddrs["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        tokenAddrs["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    function _setTokenPrices() internal {
        tokenPrices["WBTC"] = 60_000;
        tokenPrices["WETH"] = 4_000;
        tokenPrices["LINK"] = 20;
        tokenPrices["YFI"] = 35_000;
        tokenPrices["USDT"] = 1;
        tokenPrices["USDC"] = 1;
        tokenPrices["DAI"] = 1;
    }

    function _setStrategyParamAddrs() internal {
        homoraBank = 0xba5eBAf3fc1Fcca67147050Bf80462393814E54B;
        sushiSwapSpell = 0xDc9c7A2Bae15dD89271ae5701a6f4DB147BAa44C;
        token0 = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
        token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        sushiswapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        swapper = address(new UniswapV2Swapper(sushiswapRouter));
    }
}
