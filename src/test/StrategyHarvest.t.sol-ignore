// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "../../lib/forge-std/src/console.sol";

import {StrategyFixture} from "./utils/StrategyFixture.sol";
import {StrategyParams} from "../interfaces/IVault.sol";

contract StrategyHarvestTest is StrategyFixture {
    uint256 minReportDelay = 1000;

    // setup is run on before each test
    function setUp() public override {
        // setup vault
        super.setUp();
    }

    function testSetupVaultOK() public {
        console.log("address of vault", address(vault));
        assertTrue(address(0) != address(vault));
        assertEq(vault.token(), address(want));
        assertEq(vault.depositLimit(), type(uint256).max);
    }

    // TODO: add additional check on strat params
    function testSetupStrategyOK() public {
        console.log("address of strategy", address(strategy));
        assertTrue(address(0) != address(strategy));
        assertEq(address(strategy.vault()), address(vault));
    }

    // Test setMinReportDelay
    function testSetMinReportDelay() public {
        assertEq(strategy.minReportDelay(), 0);

        vm.expectRevert("!authorized");
        strategy.setMinReportDelay(minReportDelay);

        vm.prank(strategist);
        strategy.setMinReportDelay(minReportDelay);
        assertEq(strategy.minReportDelay(), minReportDelay);
    }

    // Test harvesTrigger
    function testHarvestTrigger() public {}
}
