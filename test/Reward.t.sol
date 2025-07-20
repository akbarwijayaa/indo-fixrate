// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { Core } from "../src/Core.sol";
import { Reward } from "../src/Reward.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract RewardTest is Test {
    Core public core;
    Reward public reward;
    MockUSDT public usdt;

    address public owner = address(0x0);
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        usdt = new MockUSDT();
        core = new Core(address(usdt), "FR-A", "FRA", 1_000_000, block.timestamp + 365 days);
        reward = new Reward(address(usdt), "Reward Token", "RWT", 1_000_000, block.timestamp + 365 days);

        usdt.mint(alice, 1_000_000);
        usdt.mint(bob, 1_000_000);
    }

    function testInjectReward() public {
        usdt.mint(address(this), 1000);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);

        assertEq(usdt.balanceOf(address(reward)), 1000);
    }

    function testDistributeReward() public {
        usdt.mint(address(this), 1000);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);

        vm.startPrank(alice);
        usdt.approve(address(reward), 100);
        reward.deposit(alice, address(usdt), 100);
        vm.stopPrank();

        vm.warp(block.timestamp + 90 days);
        reward.distribute();

        assertGt(reward.rewardPerTokenStored(), 0);
        assertEq(reward.lastDistribution(), block.timestamp);
    }

    function testClaimReward() public {
        usdt.mint(address(this), 1000);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);

        vm.startPrank(alice);
        usdt.approve(address(reward), 10_000);
        reward.deposit(alice, address(usdt), 10_000);
        vm.stopPrank();

        vm.startPrank(bob);
        usdt.approve(address(reward), 10_000);
        reward.deposit(bob, address(usdt), 10_000);
        vm.stopPrank();

        vm.warp(block.timestamp + 90 days);
        reward.distribute();

        vm.startPrank(alice);
        uint256 aliceReward = reward.checkRewards(alice);
        vm.stopPrank();
        console.log("Reward before claim:", aliceReward);

        vm.startPrank(bob);
        uint256 bobReward = reward.checkRewards(bob);
        vm.stopPrank();
        console.log("Reward before claim:", bobReward);

        vm.startPrank(alice);
        uint256 initialAliceReward = reward.checkRewards(alice);
        uint256 balanceAliceBefore = usdt.balanceOf(alice);
        reward.claimReward();
        vm.stopPrank();
        assertEq(usdt.balanceOf(alice), balanceAliceBefore + initialAliceReward);
        assertEq(reward.checkRewards(alice), 0);

        vm.startPrank(bob);
        uint256 initialBobReward = reward.checkRewards(bob);
        uint256 balanceBobBefore = usdt.balanceOf(bob);
        reward.claimReward();
        vm.stopPrank();
        assertEq(usdt.balanceOf(bob), balanceBobBefore + initialBobReward);
        assertEq(reward.checkRewards(bob), 0);
    }

}