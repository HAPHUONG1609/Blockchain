pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vendor is Ownable {
    IERC20 public yourToken;
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event Withdraw(address owner, uint256 amount);

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = IERC20(tokenAddress);
    }

    // ===== BUY =====
    function buyTokens() external payable {
        require(msg.value > 0, "Send ETH");

        uint256 tokensToBuy = msg.value * tokensPerEth;
        require(yourToken.balanceOf(address(this)) >= tokensToBuy, "Not enough tokens");

        yourToken.transfer(msg.sender, tokensToBuy);
        emit BuyTokens(msg.sender, msg.value, tokensToBuy);
    }

    // ===== SELL (CHECKPOINT 3) =====
    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount = 0");

        uint256 ethToReturn = amount / tokensPerEth;
        require(address(this).balance >= ethToReturn, "Vendor out of ETH");

        bool success = yourToken.transferFrom(msg.sender, address(this), amount);
        require(success, "transferFrom failed");

        (bool sent, ) = msg.sender.call{value: ethToReturn}("");
        require(sent, "ETH transfer failed");

        emit SellTokens(msg.sender, amount, ethToReturn);
    }

    // ===== OWNER =====
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH");

        (bool sent, ) = owner().call{value: balance}("");
        require(sent, "Withdraw failed");

        emit Withdraw(owner(), balance);
    }
}
