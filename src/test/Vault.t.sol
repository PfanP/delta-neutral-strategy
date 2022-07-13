// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../../lib/ds-test/test.sol";
import "../../lib/forge-std/src/Test.sol";
import "../../lib/utils/VyperDeployer.sol";


import "../IVault.sol";

contract VaultTest is Test {
    ///@notice create a new instance of VyperDeployer
    VyperDeployer vyperDeployer = new VyperDeployer();

    IVault vault;

    // Init Params
    address token = 0x0000000000000000000000000000000000000000;
    address governance = 0x0000000000000000000000000000000000000000;
    address rewards = 0x0000000000000000000000000000000000000000;
    string name = 'cVault';
    string symbol = 'cv';

    function setUp() public {
        vault = IVault(
            vyperDeployer.deployContract("Vault", abi.encode(
                token,
                governance,
                rewards,
                name,
                symbol
            ))
        );

    }

    function test_setName() public {
        vm.prank(governance);
        vault.setName('TestName');

        emit log_string(vault.name());
        require(compareStrings(vault.name(),'TestName'));
    }

    function test_setSymbol() public {
        //vault.setSymbol('TestSymbol');
        //require(compareStrings(vault.symbol(),'TestSymbol')); 
    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
