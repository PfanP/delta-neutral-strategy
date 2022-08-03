  // SPDX-License-Identifier: GPL-3.0
  pragma solidity >=0.7.0 <0.9.0;

  import {IWMasterChef} from "./IWMasterChef.sol";
    
  interface IHomoraSushiSpell {

    struct Amounts {
        uint amtAUser; // Supplied tokenA amount
        uint amtBUser; // Supplied tokenB amount
        uint amtLPUser; // Supplied LP token amount
        uint amtABorrow; // Borrow tokenA amount
        uint amtBBorrow; // Borrow tokenB amount
        uint amtLPBorrow; // Borrow LP token amount
        uint amtAMin; // Desired tokenA amount (slippage control)
        uint amtBMin; // Desired tokenB amount (slippage control)
    } 

    function acceptGovernor() external;
    function addLiquidityWERC20(address _tokenA, address _tokenB, Amounts calldata _amt) external;
    function addLiquidityWMasterChef(address _tokenA, address _tokenB, Amounts calldata _amt, uint256 _pid) external;
    function approved(address, address) external returns (bool);
    function bank() external returns (address);
    function factory() external returns (address);
    function getAndApprovePair(address _tokenA, address _tokenB) external returns (address);
    function governor() external returns (address);
    function harvestWMasterChef() external;
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes calldata) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns (bytes4);
    function pairs(address, address) external returns (address);
    function pendingGovernor() external returns (address);
    function removeLiquidityWERC20(address _tokenA, address _tokenB, Amounts calldata _amt) external;
    function removeLiquidityWMasterChef(address _tokenA, address _tokenB, Amounts calldata _amt) external;
    function router() external returns (address);
    function setPendingGovernor(address __pendingGovernor) external;
    function setWhitelistLPTokens(address[] memory _lpTokens, bool[] memory _statuses) external;
    function supportsInterface(bytes4 _interfaceId) external returns (bool);
    function sushi() external returns (address);
    function werc20() external returns (address);
    function weth() external returns (address);
    function whitelistedLpTokens(address) external returns (bool);
    function wmasterchef() external view returns (IWMasterChef);
}