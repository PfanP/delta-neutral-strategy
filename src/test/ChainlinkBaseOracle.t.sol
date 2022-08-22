pragma solidity >=0.8.13;

import "../../lib/forge-std/src/Test.sol";
import "../contracts/oracle/ConcaveChainlinkBaseOracle.sol";
import "../interfaces/oracle/IBaseOracle.sol";
import "../../lib/dn-chad-math/DopeAssMathLib.sol";

contract ConcaveChainlinkBaseOracleTest is Test {
    using SafeMath for uint256;

    ConcaveChainlinkBaseOracle oracle;

    address constant registryAddress = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;

    // tokens
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC address
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address

    function setUp() public {
        oracle = new ConcaveChainlinkBaseOracle(registryAddress);
        // tokens array
        address[] memory tokens = new address[](4);
        tokens[0] = USDT;
        tokens[1] = USDC;
        tokens[2] = DAI;
        tokens[3] = WETH;
        // decimals arra
        uint8[] memory decimals = new uint8[](4);
        decimals[0] = 6;
        decimals[1] = 6;
        decimals[2] = 18;
        decimals[3] = 18;
        // max delay times array
        uint[] memory maxDelayTimes = new uint[](4);
        maxDelayTimes[0] = 8 * 3600;
        maxDelayTimes[1] = 8 * 3600;
        maxDelayTimes[2] = 8 * 3600;
        maxDelayTimes[3] = 8 * 3600;
        oracle.setSpecificDecimals(tokens, decimals);
        oracle.setMaxDelayTimes(tokens, maxDelayTimes);
    }

    function test_blockTimestamp() public {
        emit log_uint(block.timestamp);
    }

    function test_sample() public {
        emit log_string("test_sample");
        emit log_address(address(840));
    }

    function test_getETHPx() public {
        uint256 price = oracle.getETHPx(DAI);
        emit log_uint(price);
    }
}