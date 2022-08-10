pragma solidity >=0.8.13;

import "../../lib/forge-std/src/Test.sol";

import "../contracts/oracle/UniswapV2Oracle.sol";
import "../contracts/oracle/ConcaveOracle.sol";
import "../interfaces/oracle/IBaseOracle.sol";
import "../../lib/dn-chad-math/DopeAssMathLib.sol";

contract OracleTest is Test {
    // tokens
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC address
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address

    // oracle sources
    address public constant aggregatorSource =
        0x636478DcecA0308ec6b39e3ab1e6b9EBF00Cd01c;

    ConcaveOracle oracle;

    function setUp() public {
        // nothing to do
        oracle = new ConcaveOracle();
        emit log_string("Govonor");
        emit log_address(oracle.governor());
        // oracle.initialize();

        // define tokens array
        address[] memory tokens = new address[](4);
        tokens[0] = WETH;
        tokens[1] = DAI;
        tokens[2] = USDC;
        tokens[3] = USDT;

        // define deviation array
        uint256[] memory deviations = new uint256[](4);
        deviations[0] = 1e18;
        deviations[1] = 1e18;
        deviations[2] = 1e18;
        deviations[3] = 1e18;
        // define oracles array
        IBaseOracle[][] memory oracles = new IBaseOracle[][](4);
        oracles[0] = new IBaseOracle[](1);
        oracles[0][0] = IBaseOracle(aggregatorSource);
        oracles[1] = new IBaseOracle[](1);
        oracles[1][0] = IBaseOracle(aggregatorSource);
        oracles[2] = new IBaseOracle[](1);
        oracles[2][0] = IBaseOracle(aggregatorSource);
        oracles[3] = new IBaseOracle[](1);
        oracles[3][0] = IBaseOracle(aggregatorSource);
        oracle.addPrimarySource(tokens, deviations, oracles);
    }

    function test_sample() public {
        emit log_string("test_sample");
    }

    event log_uint256(uint256);

    function test_getETHPx_WETH() public {
        emit log_string("test_getETHPx");
        uint256 px = oracle.getETHPx(WETH);
        px = px >> 112;
        emit log_string("test_getETHPx For WETH");
        emit log_uint256(px);
        assert(px == 1);
    }

    function test_getETHPx_DAI() public {
        emit log_string("test_getETHPx");
        uint256 px = oracle.getETHPx(DAI);
        emit log_string("test_getETHPx For DAI");
        emit log_uint256(px);
    }

    function test_getETHPx_USDC() public {
        emit log_string("test_getETHPx");
        uint256 px = oracle.getETHPx(USDC);
        emit log_string("test_getETHPx For USDC");
        emit log_uint256(px);
    }

    function test_getPrice_DAI_WETH() public {
        emit log_string("test_getPrice");
        (uint256 price, uint256 timestamp) = oracle.getPrice(DAI, WETH);
        emit log_string("test_getPrice For DAI-WETH");
        emit log_uint256(price);
        emit log_string("test_getPrice timestamp");
        emit log_uint256(timestamp);
        uint256 px = oracle.getETHPx(DAI);
        emit log_string("px");
        emit log_uint256(px);
        uint256 extendedPx = px * 1e18;
        emit log_string("returned price");
        emit log_uint256(price);
        emit log_string("calculated price");
        uint256 calculatedPrice = ((extendedPx * 1e18) >> 112)/1e18;
        emit log_uint256(((extendedPx * 1e18) >> 112)/1e18);
        assert(price == calculatedPrice);
    }

    function test_sort() public {
        uint256[] memory prices = new uint256[](5);
        prices[0] = 8;
        prices[1] = 2;
        prices[2] = 3;
        prices[3] = 3;
        prices[4] = 5;
        uint256 validSourceCount = 5;
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
