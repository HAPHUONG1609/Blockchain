// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // Do not change version

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    // ========= CHECKPOINT 1 =========
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    event Stake(address staker, uint256 amount);
    event Withdraw(address indexed staker, uint256 amount);

    // ========= CHECKPOINT 2 =========
    uint256 public deadline = block.timestamp + 30 seconds;
    bool public openForWithdraw;
    bool public executed;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // ========= CHECKPOINT 3 =========
    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "Already completed"
        );
        _;
    }

    // -------- STAKE --------
    function stake() public payable notCompleted {
        require(block.timestamp < deadline, "Staking period ended");
        require(msg.value > 0, "Must send ETH");

        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);

        console.log("stake()", msg.sender, msg.value);
    }

    // -------- EXECUTE --------
    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline not reached");
        require(!executed, "Already executed");

        executed = true;

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // -------- WITHDRAW --------
    function withdraw() public {
        require(openForWithdraw, "Withdraw not allowed");

        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        balances[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send ETH");

        emit Withdraw(msg.sender, amount);
    }

    // -------- TIME LEFT --------
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // -------- RECEIVE ETH --------
    receive() external payable {
        revert("Use stake()");
    }
}