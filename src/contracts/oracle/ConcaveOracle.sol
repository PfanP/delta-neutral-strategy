pragma solidity ^0.8.13;

import "../../interfaces/oracle/IBaseOracle.sol";
import "./Governable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../lib/dn-chad-math/DopeAssMathLib.sol";

contract ConcaveOracle is IBaseOracle, Governable {
    using SafeMath for uint256;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address
    mapping(address => uint256) public primarySourceCount; // Mapping from token to number of sources
    mapping(address => mapping(uint256 => IBaseOracle)) public primarySources; // Mapping from token to (mapping from index to oracle source)
    mapping(address => uint256) public maxPriceDeviations; // Mapping from token to max price deviation (multiplied by 1e18)

    uint256 public constant MIN_PRICE_DEVIATION = 1e18; // min price deviation
    uint256 public constant MAX_PRICE_DEVIATION = 1.5e18; // max price deviation
    uint256 public constant MAX_SOURCE_COUNT = 3; // max number of sources

    constructor() public initializer {
        __Governable__init();
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// PRICE CALCULATION //////////////////////////////////
    ////////////////////////////////// VIEW    FUNCTIONS //////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    function getETHPx(address token) public view override returns (uint256) {
        require(_support(token));
        uint256 candidateSourceCount = primarySourceCount[token];
        uint256[] memory prices = new uint256[](candidateSourceCount);
        // Get valid oracle sources
        // get prices from all sources
        uint256 validSourceCount = 0;
        for (uint256 idx = 0; idx < candidateSourceCount; idx++) {
            try primarySources[token][idx].getETHPx(token) returns (
                uint256 px
            ) {
                prices[validSourceCount++] = px;
            } catch {}
        }
        require(validSourceCount > 0, "no valid source");
        // sort price from min to max
        for (uint256 i = 0; i < validSourceCount - 1; i++) {
            for (uint256 j = 0; j < validSourceCount - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }

        uint256 maxPriceDeviation = maxPriceDeviations[token];
        // Algo:
        // - 1 valid source --> return price
        // - 2 valid sources
        //     --> if the prices within deviation threshold, return average
        //     --> else revert
        // - 3 valid sources --> check deviation threshold of each pair
        //     --> if all within threshold, return median
        //     --> if one pair within threshold, return average of the pair
        //     --> if none, revert
        // - revert otherwise
        if (validSourceCount == 1) {
            return prices[0]; // if 1 valid source, return
        } else if (validSourceCount == 2) {
            require(
                prices[1].mul(1e18) / prices[0] <= maxPriceDeviation,
                "too much deviation (2 valid sources)"
            );
            return DopeAssMathLib.average(prices[0], prices[1]); // if 2 valid sources, return average
        } else if (validSourceCount == 3) {
            bool midMinOk = prices[1].mul(1e18) / prices[0] <=
                maxPriceDeviation;
            bool maxMidOk = prices[2].mul(1e18) / prices[1] <=
                maxPriceDeviation;
            if (midMinOk && maxMidOk) {
                return prices[1]; // if 3 valid sources, and each pair is within thresh, return median
            } else if (midMinOk) {
                return DopeAssMathLib.average(prices[0], prices[1]); // return average
            } else if (maxMidOk) {
                return DopeAssMathLib.average(prices[1], prices[2]); // return average
            } else {
                revert("too much deviation (3 valid sources)");
            }
        } else {
            revert("too many valid sources");
        }
    }

    function getPrice(address token, address unitToken)
        public
        view
        override
        returns (uint256, uint256)
    {
        if (unitToken == WETH) {
            return (getETHPx(token).mul(1e18) >> 112, block.timestamp);
        } else {
            uint256 ethPxForToken = getETHPx(token);
            uint256 ethPxForUnit = getETHPx(token);
            // return price = token / unitToken
            return (
                DopeAssMathLib.divWad(ethPxForToken, ethPxForUnit),
                block.timestamp
            );
        }
    }

    function support(address token) external view returns (bool) {
        return _support(token);
    }

    function _support(address token) internal view returns (bool) {
        return primarySourceCount[token] > 0;
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////// SOURCE MANAGEMENT //////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////

    event AddedPrimarySource(
        address token,
        uint256 maxPriceDeviation,
        IBaseOracle[] oracles
    );

    function addPrimarySource(
        address[] memory tokens,
        uint256[] memory maxPriceDeviationList,
        IBaseOracle[][] memory oracles
    ) external onlyGov {
        require(
            tokens.length == maxPriceDeviationList.length &&
                tokens.length == oracles.length,
            "length mismatch"
        );
        // do pre checks to save gas
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                maxPriceDeviationList[i] >= MIN_PRICE_DEVIATION &&
                    maxPriceDeviationList[i] <= MAX_PRICE_DEVIATION,
                "max price deviation out of range"
            );
            require(
                MAX_SOURCE_COUNT >= oracles[i].length,
                "too many oracles"
            );
        }

        for (uint256 idx = 0; idx < tokens.length; idx++) {
            _addPrimarySource(
                tokens[idx],
                maxPriceDeviationList[idx],
                oracles[idx]
            );
        }
    }

    function _addPrimarySource(
        address token,
        uint256 maxPriceDeviation,
        IBaseOracle[] memory oracles
    ) internal {
        // do we need set an upper bound on the number of sources?
        // if so, we need to check that the number of sources is less than the upper bound
        primarySourceCount[token] = oracles.length;
        maxPriceDeviations[token] = maxPriceDeviation;
        for (uint256 idx = 0; idx < oracles.length; idx++) {
            primarySources[token][idx] = oracles[idx];
        }
        emit AddedPrimarySource(token, maxPriceDeviation, oracles);
    }
}
