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
        if (IMarket(market).totalSupply() == 0) revert NoTokensMinted();

        IERC20(IMarket(market).tokenAccepted()).transferFrom(msg.sender, address(this), amount);
        _distribute();

        emit RewardInjected(amount);
    }
    

    function _distribute() internal {
        uint256 balance = IERC20(IMarket(market).tokenAccepted()).balanceOf(address(this));
        uint256 supply = IMarket(market).totalSupply();

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

    function claimReward(address account) public {
        updateReward(account);
        uint256 reward = rewards[account];
        if (reward == 0) revert NoRewardToClaim();
        rewards[account] = 0;

        IERC20(IMarket(market).tokenAccepted()).transfer(account, reward);

    }

}
