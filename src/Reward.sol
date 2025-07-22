// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Reward is Ownable{
    address public immutable market;

    uint256 public lastDistribution;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardInjected(uint256 amount);
    event RewardDistributed(address indexed user, uint256 amount);

    error ZeroAmount();
    error TooEarly();
    error NoTokensMinted();
    error NoRewardToClaim();

    constructor(address _marketAddress) Ownable(msg.sender){
        market = _marketAddress;
    }


    function injectReward(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        IERC20(IMarket(market).tokenAccepted()).transferFrom(msg.sender, address(this), amount);

        emit RewardInjected(amount);
    }
    

    function distribute() external  {
        if (block.timestamp <= lastDistribution + 90 days) revert TooEarly();
        uint256 balance = IERC20(IMarket(market).tokenAccepted()).balanceOf(address(this));
        uint256 supply = IMarket(market).totalSupply();
        if(supply == 0) revert NoTokensMinted();

        uint256 newReward = balance;
        rewardPerTokenStored += newReward * 1e6 / supply;
        lastDistribution = block.timestamp;

        emit RewardDistributed(msg.sender, newReward);
    }

    function earned(address account) public view returns (uint256) {
        uint256 pending = IMarket(market).balanceOf(account) *
            (rewardPerTokenStored - userRewardPerTokenPaid[account]) / 1e6;
        return rewards[account] + pending;
    }

    function updateReward(address account) internal {
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _updateReward(address account) external onlyOwner {
        updateReward(account);
    }

    function claimReward() public {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NoRewardToClaim();
        rewards[msg.sender] = 0;

        IERC20(IMarket(market).tokenAccepted()).transfer(msg.sender, reward);

    }

}
