// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChef {
    // ===== Write =====
    function deposit(uint256 _pid, uint256 _amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;

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
    
    function poolInfo(uint256 _pid) 
        external 
        view 
        returns (address, uint256, uint256, uint256);

    function lpToken(uint256 _pid)
        external
        view
        returns (address);
}