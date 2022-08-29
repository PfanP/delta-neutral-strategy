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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

string constant vaultArtifact = "artifacts/Vault.json";

contract FarmToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract UniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint256 balanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));
        uint256 amountOut = (balanceOut * amountIn) / balanceIn;

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        amounts = new uint256[](1);
        amounts[0] = amountOut;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint256 balanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));
        uint256 amountOut = (balanceOut * amountIn) / balanceIn;

        amounts = new uint256[](1);
        amounts[0] = amountOut;
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint256 balanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));
        uint256 amountIn = (amountOut * balanceOut) / balanceIn;

        amounts = new uint256[](1);
        amounts[0] = amountIn;
    }
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

contract WithdrawTest is ExtendedTest, VyperTest {
    Strategy DNStrategy;
    Token vaultToken;
    FarmToken farmToken;
    UniswapRouter router;
    ConcaveOracle concaveOracle;
    IVault vault;

    address gov = 0x0000000000000000000000000000000000000010;
    address rewards = 0x0000000000000000000000000000000000000100;

    address hBank = 0x0000000000000000000000000000000000000000;
    address sushiSwapSpell = 0x0000000000000000000000000000000000000000;

    address token0 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI on ETH
    address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH on ETH
    uint256 farmLeverage = 3;
    address lpToken = 0x0000000000000000000000000000000000000000;

    address keeper = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        vaultToken = new Token();
        farmToken = new FarmToken("Sushi", "Sushi");
        router = new UniswapRouter();
        concaveOracle = new ConcaveOracle();
        vaultToken.transfer(address(router), 100 ether);
        farmToken.mint(address(router), 2000 ether);

        address _vaultAddress = deployCode(vaultArtifact);
        vault = IVault(_vaultAddress);

        string memory _name = "CVault";
        string memory _symbol = "vCNV";
        vault.initialize(
            address(vaultToken),
            gov,
            rewards,
            _name,
            _symbol //,
            //_guardian,
            //_management
        );
        vm.prank(gov);
        vault.setDepositLimit(10000 ether);
        vaultToken.approve(address(vault), 10 ether);
        vault.deposit(10 ether);

        DNStrategy = new Strategy(
            address(vault),
            hBank,
            sushiSwapSpell,
            address(router),
            token0,
            token1,
            farmLeverage,
            address(concaveOracle),
            lpToken
        );
        DNStrategy.setFarmToken(address(farmToken));
        vaultToken.transfer(address(DNStrategy), 100 ether);

        vm.prank(gov);
        vault.addStrategy(address(DNStrategy), 100, 5, 9, 10);
    }

    uint256 _longPositionId = 1;
    uint256 _shortPositionId = 2;

    uint256 _mockHarvestAmount = 0;
    uint256 _longPositionEquityETH = 1e18;
    uint256 _longPositionLoanETH = 3e18;
    uint256 _shortPositionEquityETH = 1e18;
    uint256 _shortPositionLoanETH = 3e18;
    uint256 _longLPAmount = 2e18;
    uint256 _shortLPAmount = 2e18;

    uint256 _longPositionDebtToken0 = 20e18;
    //uint _longPositionDebtToken1 = 0;
    //uint _shortPositionDebtToken0 = 0;
    uint256 _shortPositionDebtToken1 = 3e18;

    function test_withdraw_from_not_vault() public {
        DNStrategy.setShortPositionId(_shortPositionId);
        DNStrategy.setLongPositionId(_longPositionId);

        DNStrategy.initialize_farmSimulator(
            _mockHarvestAmount,
            _longPositionEquityETH,
            _longPositionLoanETH,
            _shortPositionEquityETH,
            _shortPositionLoanETH,
            _longLPAmount,
            _shortLPAmount,
            _longPositionDebtToken0,
            _shortPositionDebtToken1,
            _longPositionId,
            _shortPositionId
        );

        uint256 amountNeeded = 1 ether;
        vm.expectRevert("!vault");
        DNStrategy.withdraw(amountNeeded);
    }

    function test_withdraw() public {
        DNStrategy.setShortPositionId(_shortPositionId);
        DNStrategy.setLongPositionId(_longPositionId);

        DNStrategy.initialize_farmSimulator(
            _mockHarvestAmount,
            _longPositionEquityETH,
            _longPositionLoanETH,
            _shortPositionEquityETH,
            _shortPositionLoanETH,
            _longLPAmount,
            _shortLPAmount,
            _longPositionDebtToken0,
            _shortPositionDebtToken1,
            _longPositionId,
            _shortPositionId
        );

        vault.withdraw();
    }

    function test_withdraw_max_shares() public {
        DNStrategy.setShortPositionId(_shortPositionId);
        DNStrategy.setLongPositionId(_longPositionId);

        DNStrategy.initialize_farmSimulator(
            _mockHarvestAmount,
            _longPositionEquityETH,
            _longPositionLoanETH,
            _shortPositionEquityETH,
            _shortPositionLoanETH,
            _longLPAmount,
            _shortLPAmount,
            _longPositionDebtToken0,
            _shortPositionDebtToken1,
            _longPositionId,
            _shortPositionId
        );

        uint256 maxShares = 1 ether;
        vault.withdraw(maxShares);
    }

    function test_withdraw_max_shares_recipient() public {
        DNStrategy.setShortPositionId(_shortPositionId);
        DNStrategy.setLongPositionId(_longPositionId);

        DNStrategy.initialize_farmSimulator(
            _mockHarvestAmount,
            _longPositionEquityETH,
            _longPositionLoanETH,
            _shortPositionEquityETH,
            _shortPositionLoanETH,
            _longLPAmount,
            _shortLPAmount,
            _longPositionDebtToken0,
            _shortPositionDebtToken1,
            _longPositionId,
            _shortPositionId
        );

        uint256 maxShares = 1 ether;
        address recipient = address(9);
        vault.withdraw(maxShares, recipient);
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
