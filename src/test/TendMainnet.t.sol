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

contract TendTest is ExtendedTest, VyperTest {
    Strategy DNStrategy;
    //Token vaultToken;
    ConcaveOracle concaveOracle;
    IVault vault;
    IERC20 dai;

    address homoraGov = 0xe142BAe2338D2c691C267B054b13d38Ce6aC5442;
    address rewards = 0x0000000000000000000000000000000000000100; // Vault sends fee rewards here, Any wallet will do

    address sushiSwapSpell = 0xDc9c7A2Bae15dD89271ae5701a6f4DB147BAa44C;
    address router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // SushiSwap router

    address token0 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI on ETH
    address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH on ETH
    uint farmLeverage = 15e17;
    address lpToken = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f; // DAI<>WETh LP on SushiSwap | OR MAYBE this is the WMasterChef

    address keeper = 0x0000000000000000000000000000000000000003; // Our Bot keeper address
    address mainnetDAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address mainnetEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH on ETH
    address mainnetChainlinkRegistry = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;

    uint pid = 2; 
    address daiWhale = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    function setUp() public {
        //vaultToken = new Token();
        concaveOracle = new ConcaveOracle();

        address hBankAddress = 0xba5eBAf3fc1Fcca67147050Bf80462393814E54B;
        IHomoraBank hBank = IHomoraBank(hBankAddress);
        dai = IERC20(mainnetDAI);

        //string memory vaultArtifact = "artifacts/Vault.json";
        //address _vaultAddress = deployCode(vaultArtifact);
        //VyperDeployer vyperDeployer = new VyperDeployer();
        vault = IVault(
            //vyperDeployer.deployContract("Vault", abi.encode())
            //_vaultAddress
            deployContract("src/vyper_contracts/Vault.vy")
        );

        string memory _name = 'CVault';
        string memory _symbol = 'vCNV';
        vault.initialize(
            mainnetDAI,
            address(this),
            rewards,
            _name,
            _symbol//,
            //_guardian,
            //_management
        );
        
        DNStrategy = new Strategy(
            address(vault),
            hBankAddress,
            sushiSwapSpell,
            router,
            token1,
            farmLeverage,
            address(concaveOracle),
            lpToken,
            pid,
            mainnetEth
        );

        vault.addStrategy(
            address(DNStrategy), 
            10000, // debtRatio
            0, // _minDebtPerHarvest 
            type(uint256).max, // _maxDebtPerHarvest 
            0  // performanceFee
        );

        address[] memory users = new address[](1);
        users[0] = address(DNStrategy);

        bool[] memory userStatus = new bool[](users.length);
        for (uint i = 0; i < users.length; i++) {
            userStatus[i] = true;
        }

        vm.prank(homoraGov);
        hBank.setWhitelistUsers(users, userStatus);

    }

    function setupPosition() public {
        vault.setDepositLimit(90000e18); // This contract is the vault governor

        // Deposit token to vault
        uint amount = 1000 ether;
        vm.startPrank(daiWhale);
        dai.approve(address(vault), type(uint256).max);
        vault.deposit(amount);
        vm.stopPrank();

        emit log_uint(dai.balanceOf(address(vault)));
        // Get the tokens into the strategy 
        DNStrategy.harvest(); 
    }

    // Create a position adjuster to change the balance of the positions for testing
    // Functions: Increase / decrease loans
    // Increase / decrease equity
    function addToDNPositions(
        uint longPositionId, 
        uint shortPositionId,
        uint longEquityAdd, // Units are in DAI
        uint shortEquityAdd, // Units are in DAI
        uint longLoanAdd, // Units are in DAI
        uint shortLoanAdd // Units are in ETH
    ) public {
        vm.prank(daiWhale);
        dai.transfer(address(DNStrategy),longEquityAdd);

        uint beforeEquityAdd = DNStrategy.getCollateralETHValue(longPositionId);
        DNStrategy.openOrIncreasePositionSushiswap(
                longPositionId, 
                token0,
                token1,
                longEquityAdd,
                0,
                0, // 0 Supply of LP
                longLoanAdd, // Borrow token0
                0,
                pid 
        );

        emit log_uint(1234);
        emit log_uint(beforeEquityAdd);
        emit log_uint(DNStrategy.getCollateralETHValue(longPositionId));

        vm.prank(daiWhale);
        dai.transfer(address(DNStrategy),shortEquityAdd);
        uint beforeShortPositionAdd = DNStrategy.getCollateralETHValue(shortPositionId);
        
        DNStrategy.openOrIncreasePositionSushiswap(
            shortPositionId, 
            token0,
            token1,
            shortEquityAdd,
            0,
            0, // 0 Supply of LP
            0, // 0 Borrow of token0
            shortLoanAdd, // Borrow only Token 1
            pid 
        );  

        emit log_uint(5678);
        emit log_uint(beforeShortPositionAdd);
        emit log_uint(DNStrategy.getCollateralETHValue(shortPositionId));

    }
/*
    function removeFromDNPositions(
        uint longPositionId, 
        uint shortPositionId,
        uint longEquityRemove, // Convert To Units of DAI
        uint shortEquityRemove, // Convert To Units of DAI
        uint longLoanRemove, // Convert To Units of DAI
        uint shortLoanRemove // Convert To Units of ETH
    ) {
        
    } */ 

    function test_mainnetTend() public {
        setupPosition();

        (uint longPositionId, uint shortPositionId) = DNStrategy.getPositionIds();
        
        emit log_uint(longPositionId);
        emit log_uint(shortPositionId);

        uint longEquityAdd = 500 ether; // Units of DAI
        uint shortEquityAdd = 1000 ether; // Units of DAI
        uint longLoanAdd = 0 ether; // Units of DAI
        uint shortLoanAdd = 1e17; // Units of ETH
        addToDNPositions(
            longPositionId,
            shortPositionId,
            longEquityAdd,
            shortEquityAdd,
            longLoanAdd,
            shortLoanAdd
        );

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
        return 1e18;
    }

    function getPrice(address token0, address tokenUnit)
        external
        view
        returns (uint256, uint256)
    {   
        // For the tests it's either DAI - ETH | or ETH - DAI
        if (token0 == 0x6B175474E89094C44Da98b954EedeAC495271d0F) { // DAI
            return (588e12, 0); 
        } else if (token0 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 && tokenUnit == 0x6B175474E89094C44Da98b954EedeAC495271d0F) { // WETH - DAI
            return (1700e18, 0); 
        }
        else {
            return (1e18, 0); 
        }
    }

    function support(address token) external view returns (bool) {
        return true;
    }
}