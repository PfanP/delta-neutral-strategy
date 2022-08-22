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
    mapping(address => uint) public maxDelayTimes; // Mapping from token address to max delay time

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
        uint maxDelayTime = maxDelayTimes[_token];
        try registry.latestRoundData(_token, ETH) returns (
            uint80,
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            require(updatedAt >= block.timestamp.sub(maxDelayTime), 'delayed update time');
            return answer.toUint256().mul(2 << 111).div(10**decimal);
        } catch {
            (, int answer, , uint updatedAt, ) = registry.latestRoundData(_token, USD);
            require(updatedAt >= block.timestamp.sub(maxDelayTime), 'delayed update time');
            (, int ethAnswer, , uint ethUpdatedAt, ) = registry.latestRoundData(ETH, USD);
            require(ethUpdatedAt >= block.timestamp.sub(maxDelayTimes[ETH]), 'delayed eth-usd update time');
            if (decimal > 18) {
                // if decimal is greater than 18, the answer's decimals are greater than ETH's decimals, so we need to divide the answer by 10**(decimal - 18)
                return answer.toUint256().mul(2 << 111).div(ethAnswer.toUint256()).div(10**(decimal - 18));
            } else {
                // if decimal is less or equal than 18 (mostly are 18), the answer's decimals are less or equal than ETH's decimals, so we need to multiply the answer by 10**(18 - decimal)
                return answer.toUint256().mul(2 << 111).mul(10**(18 - decimal)).div(ethAnswer.toUint256());
            }
        }
    }

    /// @dev Return get decimals for token, if there is no decimals, get decimals from ChainlinkDetailedERC20
    function getDecimals(address _token) internal view returns (uint8) {
        uint8 decimals = specificDecimals[_token];
        if (decimals > 0) {
            return decimals;
        }
        return ChainlinkDetailedERC20(_token).decimals();
    }

    event SpecificDecimalsSet(address indexed token, uint8 decimals);
    event MaxDelayTimesSet(address indexed token, uint maxDelayTime);

    //////////// Governable ////////////
    function setSpecificDecimals(address[] calldata _tokens, uint8[] calldata _decimals) external onlyGov {
        require(_tokens.length == _decimals.length, "length mismatch");
        for (uint idx = 0; idx < _tokens.length; idx++) {
            specificDecimals[_tokens[idx]] = _decimals[idx];
            emit SpecificDecimalsSet(_tokens[idx], _decimals[idx]);
        }
    }

    function setMaxDelayTimes(address[] calldata _tokens, uint[] calldata _maxDelayTimes) external onlyGov {
        require(_tokens.length == _maxDelayTimes.length, "length mismatch");
        for (uint idx = 0; idx < _tokens.length; idx++) {
            maxDelayTimes[_tokens[idx]] = _maxDelayTimes[idx];
            emit MaxDelayTimesSet(_tokens[idx], _maxDelayTimes[idx]);
        }
    }
}
