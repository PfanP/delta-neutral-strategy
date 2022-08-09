pragma solidity >=0.8.13;

import "../../lib/forge-std/src/Test.sol";

import "../contracts/oracle/UniswapV2Oracle.sol";

contract OracleTest is Test {

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC address
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address

    function setUp() public {
        // nothing to do
    }

    function test_sample() public {
        emit log_string("test_sample");
    }

    function test_sort() public {
        uint256[] memory prices = new uint256[](5);
        prices[0] = 8;
        prices[1] = 2;
        prices[2] = 3;
        prices[3] = 3;
        prices[4] = 5;
        uint validSourceCount = 5;
        for (uint256 i = 0; i < validSourceCount - 1; i++) {
            for (uint256 j = 0; j < validSourceCount - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }
        emit log_uint(prices[0]);
        emit log_uint(prices[1]);
        emit log_uint(prices[2]);
        emit log_uint(prices[3]);
        emit log_uint(prices[4]);
    }
}
