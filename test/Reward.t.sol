// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { MarketImplementation } from "../src/MarketImplementation.sol";
import { Factory } from "../src/Factory.sol";
import { Reward } from "../src/Reward.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract RewardTest is Test {
    MarketImplementation public market;
    MarketImplementation public marketImplementation;
    Factory public factory;
    Reward public reward;
    MockUSDT public usdt;

    address public owner = address(0x123);
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        usdt = new MockUSDT();
        vm.startPrank(owner);
        marketImplementation = new MarketImplementation();
        factory = new Factory(address(marketImplementation));
        
        factory.createMarket(
            "FR-A",
            address(usdt),
            1_000_000,
            block.timestamp + 365 days
        );
        
        address marketAddress = factory.markets(0);
        market = MarketImplementation(marketAddress);
        reward = Reward(market.rewardAddress());
        vm.stopPrank();

        usdt.mint(alice, 1_000_000);
        usdt.mint(bob, 1_000_000);

    }

    function testInitialOwner() public view {
        console.log("Factory address:", address(factory));
        console.log("Factory owner:", factory.owner());
        console.log("Market address:", address(market));
        console.log("Market owner:", market.owner());
        console.log("Reward contract address:", address(reward));
        console.log("Reward contract owner:", reward.owner());
    }

    function testInjectRewardWithNoTokensMinted() public {
        usdt.mint(owner, 1000);
        vm.startPrank(owner);
        usdt.approve(address(reward), 1000);
        vm.expectRevert();
        reward.injectReward(1000);
        vm.stopPrank();
        assertEq(usdt.balanceOf(address(reward)), 0);
    }

    function testDistributeReward() public {
        vm.startPrank(alice);
        usdt.approve(address(market), 100);
        market.deposit(alice, address(usdt), 100, 30 days);
        vm.stopPrank();

        usdt.mint(owner, 1000);
        vm.startPrank(owner);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);
        vm.stopPrank();

        assertGt(reward.rewardPerTokenStored(), 0);
        assertEq(reward.lastDistribution(), block.timestamp);
    }

    function testClaimReward() public {
        vm.startPrank(alice);
        usdt.approve(address(market), 10_000);
        market.deposit(alice, address(usdt), 10_000, 30 days);
        vm.stopPrank();

        vm.startPrank(bob);
        usdt.approve(address(market), 10_000);
        market.deposit(bob, address(usdt), 10_000, 30 days);
        vm.stopPrank();

        vm.startPrank(owner);
        usdt.mint(owner, 1000);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);
        vm.stopPrank();

        // vm.startPrank(alice);
        // uint256 aliceReward = reward.earned(alice);
        // vm.stopPrank();
        // console.log("Alice's reward before claim:", aliceReward);

        // vm.startPrank(bob);
        // uint256 bobReward = reward.earned(bob);
        // vm.stopPrank();
        // console.log("Bob's reward before claim:", bobReward);

        // vm.startPrank(alice);
        // uint256 initialAliceReward = reward.earned(alice);
        // uint256 balanceAliceBefore = usdt.balanceOf(alice);
        // reward.claimReward(address(alice));
        // vm.stopPrank();
        // assertEq(usdt.balanceOf(alice), balanceAliceBefore + initialAliceReward);
        // assertEq(reward.earned(alice), 0);

        // vm.startPrank(bob);
        // uint256 initialBobReward = reward.earned(bob);
        // uint256 balanceBobBefore = usdt.balanceOf(bob);
        // reward.claimReward(address(bob));
        // vm.stopPrank();
        // assertEq(usdt.balanceOf(bob), balanceBobBefore + initialBobReward);
        // assertEq(reward.earned(bob), 0);
    }

}