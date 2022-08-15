pragma solidity >=0.8.13;

import "../../lib/forge-std/src/Test.sol";

import "../contracts/oracle/UniswapV2Oracle.sol";
import "../contracts/oracle/ConcaveOracle.sol";
import "../interfaces/oracle/IBaseOracle.sol";
import "../../lib/dn-chad-math/DopeAssMathLib.sol";

contract HomoraFarmSimulator is Test {
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
        
    }

}
