// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "../../lib/forge-std/src/console.sol";

//import {StrategyParams} from "../interfaces/IVault.sol";

import {Strategy} from "../contracts/Strategy.sol";
import {ExtendedTest} from "./utils/ExtendedTest.sol";
import {IVault} from "../interfaces/IVault.sol";
import "../../utils/VyperTest.sol";
import {VyperTest} from "../../utils/VyperTest.sol";
//import "../Token.sol";
import {IHomoraBank} from "../interfaces/IHomoraBank.sol";
import {IERC20} from "../interfaces/IERC20.sol";

string constant vaultArtifact = "artifacts/Vault.json";

contract HarvestTest is ExtendedTest, VyperTest {
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
    uint farmLeverage = 1e18;
    address lpToken = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f; // DAI<>WETh LP on SushiSwap | OR MAYBE this is the WMasterChef

    address keeper = 0x0000000000000000000000000000000000000003; // Our Bot keeper address
    address mainnetDAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint pid = 2; 
    address daiWhale = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    function setUp() public {
        //vaultToken = new Token();
        concaveOracle = new ConcaveOracle();

        address hBankAddress = 0xba5eBAf3fc1Fcca67147050Bf80462393814E54B;
        IHomoraBank hBank = IHomoraBank(hBankAddress);
        dai = IERC20(mainnetDAI);

        address _vaultAddress = deployCode(vaultArtifact);
        vault = IVault(_vaultAddress);

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
        vault.setDepositLimit(90000e18);
        
        DNStrategy = new Strategy(
            address(vault),
            hBankAddress,
            sushiSwapSpell,
            router,
            token1,
            farmLeverage,
            address(concaveOracle),
            lpToken,
            pid
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

    /*
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
    */

    function setupPosition() public { // This contract is the vault governor

        // Deposit token to vault
        uint amount = 1000 ether;
        vm.startPrank(daiWhale);
        dai.approve(address(vault), type(uint256).max);
        vault.deposit(amount);
        vm.stopPrank();

        emit log_uint(dai.balanceOf(address(vault)));
        // Get the tokens into the strategy 
    }


    function test_mainnetHarvest() public {
        setupPosition();
        
        vm.startPrank(daiWhale);
        dai.transfer(address(DNStrategy), 9000 ether);
        vm.stopPrank();
        DNStrategy.harvest(); 

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
        return (1000, 0); 
    }

    function support(address token) external view returns (bool) {
        return true;
    }
}