// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChef {
    // ===== Write =====
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function harvest(uint256 _pid, address _to) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);
}