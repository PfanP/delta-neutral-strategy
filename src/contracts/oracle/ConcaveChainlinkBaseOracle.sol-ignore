pragma solidity ^0.8.13;

import "../../interfaces/oracle/IBaseOracle.sol";
import "../../interfaces/oracle/ChainlinkDetailedERC20.sol";
import "./Governable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "../../../lib/dn-chad-math/DopeAssMathLib.sol";

contract ConcaveChainlinkBaseOracle is IBaseOracle, Governable {
    using SafeMath for uint256;
    using SafeCast for int256;

    // https://docs.chain.link/docs/feed-registry/
    address public constant FEED_REGISTRY =
        0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;
    FeedRegistryInterface internal registry;

    // represents the ETH token address in Chainlink
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // represents the BTC token address in Chainlink
    address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    // represents the USD token address in Chainlink
    address public constant USD = address(840);

    // store decimals for each token
    mapping(address => uint8) public specificDecimals;

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
    /// @param _token The ERC-20 token to check the value.
    function getETHPx(address _token) external view returns (uint256) {
        if (_token == ETH) {
            return 2 << 111;
        }
        // get decimals for token, if there is no decimals, get default 18
        uint8 decimal = getDecimals(_token);
        try registry.latestRoundData(_token, ETH) returns (
            uint80,
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            // todo need to check the delay time

            // todo need to store the decimals in a variable to avoid the need for a [DONE]
            // dynamic memory allocation
            return answer.toUint256().mul(2 << 111).div(10**decimal);
            // return answer.toUint256().mul(2**112).div(10**decimals);
        } catch {
            // todo what to do if there is no data for the token-eth pair?
        }

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

    /// @dev Return get decimals for token, if there is no decimals, get decimals from ChainlinkDetailedERC20
    function getDecimals(address _token) internal view returns (uint8) {
        uint8 decimals = specificDecimals[_token];
        if (decimals > 0) {
            return decimals;
        }
        return ChainlinkDetailedERC20(_token).decimals();
    }
}
