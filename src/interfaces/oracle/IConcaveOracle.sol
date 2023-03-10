pragma solidity ^0.8.13;

import "./IBaseOracle.sol";

interface IConcaveOracle {

    /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
    /// @param token The ERC-20 token to check the value.
    function getETHPx(address token) external view returns (uint256);

    /// @dev Return the price of token0/token1, multiplied by 1e18
    /// @return The price of token0/token1, and the time timstamp
    function getPrice(address token0, address tokenUnit)
        external
        view
        returns (uint256, uint256);

    // support token or not
    function support(address token) external view returns (bool);
}
