// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Core } from "./Core.sol";
import "forge-std/console.sol";


contract Reward is Core {
    uint256 public lastDistribution;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardInjected(uint256 amount);
    event RewardDistributed(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    error InvalidRewardAmount(uint256 amount);
    error TooEarly(uint256 lastDistribution, uint256 currentTime);
    error NoTokensMinted();
    error NoRewardToClaim();

    constructor(
        address _tokenAccepted,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _maturity
    )
        Core(_tokenAccepted, _name, _symbol, _maxSupply, _maturity)
    {}


    function injectReward(uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidRewardAmount(amount);
        IERC20(tokenAccepted).transferFrom(msg.sender, address(this), amount);

        emit RewardInjected(amount);
    }
    

    function distribute() external onlyOwner {
        if (block.timestamp <= lastDistribution + 90 days) revert TooEarly(lastDistribution, block.timestamp);
        uint256 balance = IERC20(tokenAccepted).balanceOf(address(this)) - totalSupply();
        console.log("Distributing reward, balance:", balance);
        uint256 supply = totalSupply();
        if(supply == 0) revert NoTokensMinted();

        uint256 newReward = balance;
        rewardPerTokenStored += newReward * 1e6 / supply;
        lastDistribution = block.timestamp;

        emit RewardDistributed(msg.sender, newReward);
    }

    function updateReward(address account) internal {
        rewards[account] += balanceOf(account) * (rewardPerTokenStored - userRewardPerTokenPaid[account]) / 1e6;
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);
        if (from != address(0)) updateReward(from);
        if (to != address(0)) updateReward(to);
    }

    function checkRewards(address account) public returns (uint256 userReward) {
        userReward = rewards[account] += balanceOf(account) * (rewardPerTokenStored - userRewardPerTokenPaid[account]) / 1e6;
    }

    function claimReward() public {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NoRewardToClaim();

        updateReward(msg.sender);
        rewards[msg.sender] = 0;
        IERC20(tokenAccepted).transfer(msg.sender, reward);
    }

}
