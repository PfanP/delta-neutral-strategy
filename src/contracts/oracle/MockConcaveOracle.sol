pragma solidity ^0.8.13;

import "../../interfaces/oracle/IBaseOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockConcaveOracle is IBaseOracle {
    using SafeMath for uint256;

    function getETHPx(address token) external view returns (uint256) {
        if (token == 0xf2edF1c091f683E3fb452497d9a98A49cBA84666 || 
        token == 0x6B175474E89094C44Da98b954EedeAC495271d0F) {
            //DAI
            return 588e12;
        }
        if (token == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ||
        token == 0xce88D2C5D5a2efe7AE1024D9D34A32a753C1C719) {
            return uint256(1e18).mul(2**112);
        }
        return uint256(1e18).mul(2**112);
    }

    function getPrice(address token0, address tokenUnit)
        external
        view
        returns (uint256, uint256)
    {
        // For the tests it's either DAI - ETH | or ETH - DAI
        if (
            token0 == 0x6B175474E89094C44Da98b954EedeAC495271d0F || // Mainnet DAI
            token0 == 0xf2edF1c091f683E3fb452497d9a98A49cBA84666 // Goerli DAI)
        ) {
            // DAI
            return (588e12, 1661493888);
        } else if (
            (token0 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 || 
            token0 == 0xce88D2C5D5a2efe7AE1024D9D34A32a753C1C719) &&
            (tokenUnit == 0x6B175474E89094C44Da98b954EedeAC495271d0F || 
                tokenUnit == 0xf2edF1c091f683E3fb452497d9a98A49cBA84666)) {
            // WETH - DAI
            return (1700e18, 1661493888);
        } else {
            return (1e18, 1661493888);
        }
    }

    function support(address token) external view returns (bool) {
        return true;
    }
}
