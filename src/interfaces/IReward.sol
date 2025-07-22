// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

interface IReward {
    function _updateReward(address account) external;
    function checkRewards(address account) external returns (uint256);
    function claimReward() external;
    function injectReward(uint256 amount) external;
    function distribute() external;
    function market() external view returns (address);
    function lastDistribution() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);
}
