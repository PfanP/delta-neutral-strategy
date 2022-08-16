pragma solidity ^0.8.13;

import "../../interfaces/oracle/IBaseOracle.sol";
import "./Governable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "../../../lib/dn-chad-math/DopeAssMathLib.sol";

contract ConcaveChainlinkBaseOracle is IBaseOracle, Governable {
    using SafeMath for uint256;

    // https://docs.chain.link/docs/feed-registry/
    address public constant FEED_REGISTRY = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;
    FeedRegistryInterface internal registry;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address public constant USD = address(840);

    /**
     * Network: Ethereum Mainnet
     * Feed Registry: 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
     * Network: Kovan
     * Feed Registry: 0xAa7F6f7f507457a1EE157fE97F6c7DB2BEec5cD0
     */
    constructor(address _registry) public {
        __Governable__init();
        registry = FeedRegistryInterface(_registry);
    }

    /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
    /// @param token The ERC-20 token to check the value.
    function getETHPx(address token) external view returns (uint256) {
        return 0;
    }

    /// @dev Return the price of token0/token1, multiplied by 1e18
    /// @return The price of token0/token1, and the time timstamp
    function getPrice(address token0, address tokenUnit)
        external
        view
        returns (uint256, uint256)
    {
        return (0, 0);
    }
}
