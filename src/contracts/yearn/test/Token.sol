// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    mapping(address => bool) public _blocked;
    uint8 private _decimals;

    constructor(uint8 decimals_) ERC20("Concave test token", "TEST") {
        _mint(msg.sender, 30000 * 10**uint256(18));
        _decimals = decimals_;
    }

    function _setBlocked(address user, bool value) public virtual {
        _blocked[user] = value;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        require(!_blocked[to], "Token transfer refused. Receiver is on blacklist");
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract TokenNoReturn {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => bool) public _blocked;

    constructor(uint8 decimals_) {
        name = "concave test token";
        symbol = "TEST";
        decimals = decimals_;
        balanceOf[msg.sender] = 30000 * 10**uint256(decimals);
        totalSupply = 30000 * 10**uint256(decimals);
    }



    function _setBlocked(address user, bool value) public virtual {
        _blocked[user] = value;
    }

    function transfer(address receiver, uint256 amount) external {
        require(!_blocked[receiver], "Token transfer refused. Receiver is on blacklist");
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        balanceOf[receiver] = balanceOf[receiver] + amount;
        emit Transfer(msg.sender, receiver, amount);
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external {
        require(!_blocked[receiver], "Token transfer refused. Receiver is on blacklist");
        allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount;
        balanceOf[sender] = balanceOf[sender] - amount;
        balanceOf[receiver] = balanceOf[receiver] + amount;
        emit Transfer(sender, receiver, amount);
    }
}

contract TokenFalseReturn is Token {
    constructor(uint8 _decimals) Token(_decimals) {}

    function transfer(address receiver, uint256 amount) public virtual override returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) public virtual override returns (bool) {
        return false;
    }
}