pragma solidity >=0.8.13;

import "../../lib/forge-std/src/Test.sol";

import "../contracts/oracle/UniswapV2Oracle.sol";

contract OracleTest is Test {

    function setUp() public {
        // nothing to do
    }

    function test_sample() public {
        emit log_string("test_sample");
    }

}