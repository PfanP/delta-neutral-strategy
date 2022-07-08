// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IVault {
    function setSymbol(string calldata symbol) external;
    function setName(string calldata name) external;
    function name() external view returns (string memory);

}
