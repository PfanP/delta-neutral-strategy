/*

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

//import "../../lib/ds-test/test.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import "../../utils/VyperDeployer.sol";
import "../contracts/Strategy.sol";

import "../interfaces/IVault.sol";
import "../Token.sol";

contract VaultTest is Test {
    ///@notice create a new instance of VyperDeployer
    //VyperDeployer vyperDeployer = new VyperDeployer();
    string constant vaultArtifact = "artifacts/Vault.json";

    address _vaultAddress = deployCode(vaultArtifact);

    IVault vault;
    Token testToken;

    // Init Params
    //address token = 0x0000000000000000000000000000000000000000;
    address governance = 0x462a8BFFD42544eEE309c64104693b02051fe854;
    address rewards = 0x0000000000000000000000000000000000000000;
    string name = 'cVault';
    string symbol = 'cv';

    function setUp() public {
        testToken = new Token();

        //uint userBal = testToken.balanceOf(address(this));
        //emit log_uint(userBal);
        /*
        vault = IVault(
            vyperDeployer.deployContract("Vault", abi.encode())
        ); */ 

        /*
        vault = IVault(
            //vyperDeployer.deployContract("Vault", abi.encode())
            _vaultAddress
        );
        vault.initialize(
                address(testToken),
                governance,
                rewards,
                name,
                symbol
        );

        //testToken.transfer(address(vault), 100e18);
        //uint vaultBal = testToken.balanceOf(address(vault));
        //emit log_uint(vaultBal);
    }

    function test_deposit() public {
        vm.prank(governance);
        setUp();
        vault.setDepositLimit(90000e18);
        // Set Vault spend allowance 
        testToken.approve(address(vault), type(uint256).max);

        uint amount = 1e18;
        vault.deposit(amount);

        emit log_uint(vault.returnShares(address(this)));
    }

    function test_withdraw() public {
        test_deposit();

        uint maxShares = 1e17;
        uint maxLoss = 1;
        uint value = vault.withdraw(maxShares, msg.sender, maxLoss);
        emit log_uint(value);
    }
/*
    function test_setName() public {
        vm.prank(governance);
        vault.setName('TestName');
        emit log_string(vault.name());
        require(compareStrings(vault.name(),'TestName'));
    }

    function test_setSymbol() public {
        vm.prank(governance);
        vault.setSymbol('TestSymbol');
        emit log_string(vault.symbol());
        require(compareStrings(vault.symbol(),'TestSymbol')); 
    }
*/ 


/*
    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
*/ 