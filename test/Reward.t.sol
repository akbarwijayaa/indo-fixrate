// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { Market } from "../src/Market.sol";
import { Factory } from "../src/Factory.sol";
import { Reward } from "../src/Reward.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract RewardTest is Test {
    Market public market;
    Market public marketImplementation;
    Factory public factory;
    Reward public reward;
    MockUSDT public usdt;

    address public owner = address(0x0);
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        usdt = new MockUSDT();
        marketImplementation = new Market();
        factory = new Factory(address(marketImplementation));
        
        factory.createMarket(
            address(usdt),
            "FR-A",
            "FRA",
            1_000_000,
            block.timestamp + 365 days
        );
        
        address marketAddress = factory.markets(0);
        market = Market(marketAddress);
        reward = Reward(market.rewardAddress());

        usdt.mint(alice, 1_000_000);
        usdt.mint(bob, 1_000_000);
    }

    function testInjectRewardWithNoTokensMinted() public {
        usdt.mint(address(this), 1000);
        usdt.approve(address(reward), 1000);
        vm.expectRevert(Reward.NoTokensMinted.selector);
        reward.injectReward(1000);

        assertEq(usdt.balanceOf(address(reward)), 0);
    }

    function testDistributeReward() public {
        vm.startPrank(alice);
        usdt.approve(address(market), 100);
        market.deposit(alice, address(usdt), 100);
        vm.stopPrank();

        usdt.mint(address(this), 1000);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);

        assertGt(reward.rewardPerTokenStored(), 0);
        assertEq(reward.lastDistribution(), block.timestamp);
    }

    function testClaimReward() public {
        vm.startPrank(alice);
        usdt.approve(address(market), 10_000);
        market.deposit(alice, address(usdt), 10_000);
        vm.stopPrank();

        vm.startPrank(bob);
        usdt.approve(address(market), 10_000);
        market.deposit(bob, address(usdt), 10_000);
        vm.stopPrank();

        usdt.mint(address(this), 1000);
        usdt.approve(address(reward), 1000);
        reward.injectReward(1000);

        vm.startPrank(alice);
        uint256 aliceReward = reward.earned(alice);
        vm.stopPrank();
        console.log("Alice's reward before claim:", aliceReward);

        vm.startPrank(bob);
        uint256 bobReward = reward.earned(bob);
        vm.stopPrank();
        console.log("Bob's reward before claim:", bobReward);

        vm.startPrank(alice);
        uint256 initialAliceReward = reward.earned(alice);
        uint256 balanceAliceBefore = usdt.balanceOf(alice);
        reward.claimReward();
        vm.stopPrank();
        assertEq(usdt.balanceOf(alice), balanceAliceBefore + initialAliceReward);
        assertEq(reward.earned(alice), 0);

        vm.startPrank(bob);
        uint256 initialBobReward = reward.earned(bob);
        uint256 balanceBobBefore = usdt.balanceOf(bob);
        reward.claimReward();
        vm.stopPrank();
        assertEq(usdt.balanceOf(bob), balanceBobBefore + initialBobReward);
        assertEq(reward.earned(bob), 0);
    }

}