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

contract PositionSimulator is ExtendedTest, VyperTest {
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
    address lpToken = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f; // DAI<>WETh LP on SushiSwap | OR MAYBE this is the WMasterChef

    address keeper = 0x0000000000000000000000000000000000000003; // Our Bot keeper address
    address mainnetDAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address mainnetEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH on ETH
    address mainnetChainlinkRegistry = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;

    uint pid = 2; 
    address daiWhale = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    function setUpPositionSimulator(
        uint farmLeverage
    ) public {

        //vaultToken = new Token();
        concaveOracle = new ConcaveOracle();

        address hBankAddress = 0xba5eBAf3fc1Fcca67147050Bf80462393814E54B;
        IHomoraBank hBank = IHomoraBank(hBankAddress);
        dai = IERC20(mainnetDAI);

        string memory vaultArtifact = "precompiled/Vault.json";
        address _vaultCompiled = deployCode(vaultArtifact);
        //VyperDeployer vyperDeployer = new VyperDeployer();
        vault = IVault(
            //vyperDeployer.deployContract("Vault", abi.encode())
            _vaultCompiled
            //deployContract("src/vyper_contracts/Vault.vy")
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

    ///////// Position Management Tools ////////////////
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

        vm.prank(daiWhale);
        dai.transfer(address(DNStrategy),shortEquityAdd);
        
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
    }

    function removeFromDNPositions(
        uint positionId, 
        uint amtLpTake, // Convert To Units of DAI
        uint amtLpWithdraw,
        uint amtRepayToken0, // Convert To Units of DAI
        uint amtRepayToken1, // Convert To Units of DAI
        uint amountLpRepay // Convert To Units of ETH
    ) public {
        (,,,uint lpAmount) = DNStrategy.getPositionInfo(positionId);
        emit log_uint(lpAmount);

        DNStrategy.reducePositionSushiswap(
            positionId,
            token0,
            token1,
            amtLpTake,
            amtLpWithdraw,
            amtRepayToken0, // amt repay token0
            amtRepayToken1, // amt repay token1
            amountLpRepay   // amount Lp repay
        );
    } 

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