// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import { Strategy } from "../../contracts/strategies/sushiswap/SushiBaseStrategy.sol";
import { MockERC20 } from "../mock/Tokens.sol";
import { IVault } from "../../interfaces/IVault.sol";
import { VyperDeployer } from "../../../utils/VyperDeployer.sol";

/// @dev SYN/ETH Sushi LP farming test
/// TODO: check deposit, harvest, withdraw, autocompound feature
/// NOTE: this is for testing env
/// SYN-WETH LP: 0x4A86C01d67965f8cB3d0AAA2c655705E64097C31
/// SYN-WETH Pool ID: 305
/// Sushi Masterchef: 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd
/// Sushiswap router: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F

contract SushiBaseStrategyTest is Test {
    IVault vault;
    VyperDeployer vyperDeployer = new VyperDeployer();
    address synLP = address(0x4A86C01d67965f8cB3d0AAA2c655705E64097C31);
    address masterchef = address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address router = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function setup() public {
        vault = IVault(
            vyperDeployer.deployContract("Vault", abi.encode(weth))
        );
    }


}