  // SPDX-License-Identifier: GPL-3.0
  pragma solidity >=0.7.0 <0.9.0;

  interface IHomoraBank {
//   struct Bank {
//     bool isListed; // Whether this market exists.
//     uint8 index; // Reverse look up index for this bank.
//     address cToken; // The CToken to draw liquidity from.
//     uint reserve; // The reserve portion allocated to Homora protocol.
//     uint totalDebt; // The last recorded total debt since last action.
//     uint totalShare; // The total debt share count across all open positions.
//   }

//   struct Position {
//     address owner; // The owner of this position.
//     address collToken; // The ERC1155 token used as collateral for this position.
//     uint collId; // The token id used as collateral.
//     uint collateralSize; // The size of collateral token for this position.
//     uint debtMap; // Bitmap of nonzero debt. i^th bit is set iff debt share of i^th bank is nonzero.
//     mapping(address => uint) debtShareOf; // The debt share for each token.
//   }
    function EXECUTOR() external returns (address);
    function POSITION_ID() external returns (uint256);
    function SPELL() external returns (address);
    function _GENERAL_LOCK() external returns (uint256);
    function _IN_EXEC_LOCK() external returns (uint256);
    function acceptGovernor() external;
    function accrue(address) external;
    function accrueAll(address[] memory) external;
    function addBank(address, address) external;
    function allBanks(uint256) external returns (address);
    function allowBorrowStatus() external returns (bool);
    function allowContractCalls() external returns (bool);
    function allowRepayStatus() external returns (bool);
    function bankStatus() external returns (uint256);
    function banks(address) external returns (bool, uint8, address, uint256, uint256, uint256);
    function borrow(address, uint256) external;
    function borrowBalanceCurrent(uint256, address) external returns (uint256);
    function borrowBalanceStored(uint256, address) external view returns (uint256);
    function cTokenInBank(address) external returns (bool);
    function caster() external returns (address);
    function everWhitelistedUsers(address) external returns (bool);
    function exec() external returns (address);
    function execute(uint256, address, bytes calldata) external returns (uint256);
    function feeBps() external returns (uint256);
    function getBankInfo(address) external view returns (bool, address, uint256, uint256, uint256);
    function getBorrowETHValue(uint256) external view returns (uint256);
    function getCollateralETHValue(uint256) external view returns (uint256);
    function getCurrentPositionInfo() external returns (address, address, uint256, uint256);
    function getPositionDebtShareOf(uint256, address) external view returns (uint256);
    function getPositionDebts(uint256) external view returns (address[] memory, uint256[] memory);
    function getPositionInfo(uint256) external view returns (address, address, uint256, uint256);
    function governor() external returns (address);
    function initialize(address, uint256) external;
    function liquidate(uint256, address, uint256) external;
    function nextPositionId() external returns (uint256);
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes calldata) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns (bytes4);
    function oracle() external view returns (address);
    function pendingGovernor() external returns (address);
    function positions(uint256) external returns (address, address, uint256, uint256, uint256);
    function putCollateral(address, uint256, uint256) external;
    function repay(address, uint256) external;
    function setAllowContractCalls(bool) external;
    function setBankStatus(uint256) external;
    // function setCreditLimits(tuple[]) external;
    function setExec(address) external;
    function setFeeBps(uint256) external;
    function setOracle(address) external;
    function setPendingGovernor(address) external;
    function setWhitelistContractWithTxOrigin(address[] memory, address[] memory, bool[] memory) external;
    function setWhitelistSpells(address[] memory, bool[] memory) external;
    function setWhitelistTokens(address[] memory, bool[] memory) external;
    function setWhitelistUsers(address[] memory, bool[] memory) external;
    function setWorker(address) external;
    function support(address) external view returns (bool);
    function supportsInterface(bytes4) external returns (bool);
    function takeCollateral(address, uint256, uint256) external;
    function transmit(address, uint256) external;
    function whitelistedContractWithTxOrigin(address, address) external returns (bool);
    function whitelistedSpells(address) external returns (bool);
    function whitelistedTokens(address) external returns (bool);
    function whitelistedUserBorrowShares(address, address) external returns (uint256);
    function whitelistedUserCreditLimits(address, address) external returns (uint256);
    function whitelistedUsers(address) external returns (bool);
    function withdrawReserve(address, uint256) external;
    function worker() external returns (address);
}