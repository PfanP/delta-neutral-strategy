  // SPDX-License-Identifier: GPL-3.0
  pragma solidity >=0.7.0 <0.9.0;

  interface IWMasterchef {
    function balanceOf(address, uint256) external returns (uint256);
    function balanceOfBatch(address[] memory, uint256[] memory) external returns (uint256[] memory);
    function burn(uint256, uint256) external returns (uint256);
    function chef() external returns (address);
    function decodeId(uint256) external returns (uint256, uint256);
    function encodeId(uint256, uint256) external returns (uint256);
    function getUnderlyingRate(uint256) external returns (uint256);
    function getUnderlyingToken(uint256) external returns (address);
    function isApprovedForAll(address, address) external returns (bool);
    function mint(uint256, uint256) external returns (uint256);
    function safeBatchTransferFrom(address, address, uint256[] memory , uint256[] memory, bytes calldata) external;
    function safeTransferFrom(address, address, uint256, uint256, bytes calldata) external;
    function setApprovalForAll(address, bool) external;
    function supportsInterface(bytes4) external returns (bool);
    function sushi() external returns (address);
    function uri(uint256) external returns (string memory);
}