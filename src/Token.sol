// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    mapping(address => bool) public _blocked;

    constructor() public ERC20("vCNVTest", "vCNVTest") {
        uint decimals = 18;
        _mint(msg.sender, 30000 * 10**uint256(decimals));
    }

    function _setBlocked(address user, bool value) public virtual {
        _blocked[user] = value;
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
