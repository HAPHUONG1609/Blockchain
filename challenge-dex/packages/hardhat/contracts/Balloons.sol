//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Balloons is ERC20 {
    event ApproveSuccess(address indexed owner, address indexed spender, uint256 value);
    constructor() ERC20("Balloons", "BAL") {
        _mint(msg.sender, 1000 ether); // mints 1000 balloons!
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        
        // === EMIT EVENT MỚI ===
        emit ApproveSuccess(_msgSender(), spender, amount);
        // =======================

        return true;
    }
}


