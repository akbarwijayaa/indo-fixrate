// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { Router } from "../src/Router.sol";
import { Factory } from "../src/Factory.sol";
import { MarketImplementation } from "../src/MarketImplementation.sol";
import { Reward } from "../src/Reward.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";

contract RouterTest is Test {
    Router public router;
    Factory public factory;
    MarketImplementation public marketImplementation;
    MarketImplementation public market;
    Reward public reward;
    MockUSDT public usdt;
    
    address public owner = address(0x123);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public marketAddress;

    function setUp() public {
        usdt = new MockUSDT();

        vm.startPrank(owner);
        marketImplementation = new MarketImplementation();
        factory = new Factory(address(marketImplementation));
        router = new Router(address(factory));

        factory.createMarket(
            "Test Market",
            address(usdt),
            1_000_000,
            block.timestamp + 365 days
        );

        marketAddress = factory.markets(0);
        market = MarketImplementation(marketAddress);
        reward = Reward(market.rewardAddress());
        vm.stopPrank();

        usdt.mint(alice, 10_000);
        usdt.mint(bob, 10_000);
    }

    function testRouterDeposit() public {
        uint256 depositAmount = 1000;

        vm.startPrank(alice);
        usdt.approve(address(router), depositAmount);
        
        uint256 initialUsdtBalance = usdt.balanceOf(alice);
        uint256 initialMarketBalance = MarketImplementation(marketAddress).balanceOf(alice);
        
        router.deposit(marketAddress, alice, depositAmount, 30 days);
        
        assertEq(usdt.balanceOf(alice), initialUsdtBalance - depositAmount);
        assertEq(MarketImplementation(marketAddress).balanceOf(alice), initialMarketBalance + depositAmount);
        
        vm.stopPrank();
    }

    function testRouterRedeem() public {
        uint256 depositAmount = 1000;
        uint256 redeemAmount = 500;

        vm.startPrank(alice);
        
        usdt.approve(address(router), depositAmount);
        router.deposit(marketAddress, alice, depositAmount, 30 days);
        
        uint256 initialUsdtBalance = usdt.balanceOf(alice);
        uint256 initialMarketBalance = MarketImplementation(marketAddress).balanceOf(alice);
        
        skip(30 days);

        router.redeem(marketAddress, alice, redeemAmount);
        
        assertEq(usdt.balanceOf(alice), initialUsdtBalance + redeemAmount);
        assertEq(MarketImplementation(marketAddress).balanceOf(alice), initialMarketBalance - redeemAmount);
        
        vm.stopPrank();
    }

    function testGetMarketInfo() public view {
        (
            address tokenAccepted,
            uint256 maxSupply,
            uint256 maturity,
            bool isActive
        ) = router.getMarketInfo(marketAddress);

        assertEq(tokenAccepted, address(usdt));
        assertEq(maxSupply, 1_000_000);
        assertGt(maturity, block.timestamp);
        assertTrue(isActive);
    }

    function testDepositToInvalidMarket() public {
        vm.startPrank(alice);
        
        usdt.approve(address(router), 1000);
        
        vm.expectRevert(Router.MarketNotFound.selector);
        router.deposit(address(0x123), alice, 1000, 30 days);

        vm.stopPrank();
    }

    function testDepositZeroAmount() public {
        vm.startPrank(alice);
        
        vm.expectRevert(Router.InvalidAmount.selector);
        router.deposit(marketAddress, alice, 0, 30 days);

        vm.stopPrank();
    }

    function testInitialOwner() public {
        console.log("Factory address:", address(factory));
        console.log("Owner of Factory:", factory.owner());
        console.log("Market address:", marketAddress);
        console.log("Owner of Market:", market.owner());
        console.log("Reward address:", address(reward));
        console.log("Owner of Reward:", reward.owner());
        console.log("MarketImplementation address:", address(marketImplementation));
        console.log("Owner of MarketImplementation:", marketImplementation.owner());
    }

    function testDepositToInactiveMarket() public {
        vm.startPrank(owner);

        factory.createMarket(
            "Expired Market",
            address(usdt),
            1_000_000,
            block.timestamp + 100
        );
        
        address expiredMarketAddress = factory.markets(1);
        vm.stopPrank();

        skip(101);
        vm.startPrank(owner);
        factory.maturedMarket(expiredMarketAddress);
        vm.stopPrank();
        
        vm.startPrank(alice);
        usdt.approve(address(router), 1000);
        vm.expectRevert(Router.MarketNotActive.selector);
        router.deposit(expiredMarketAddress, alice, 1000, 30 days);

        vm.stopPrank();
    }

    function testDepositToDifferentRecipient() public {
        uint256 depositAmount = 1000;

        vm.startPrank(alice);
        
        usdt.approve(address(router), depositAmount);
        
        uint256 initialAliceUsdtBalance = usdt.balanceOf(alice);
        uint256 initialBobMarketBalance = MarketImplementation(marketAddress).balanceOf(bob);
        
        router.deposit(marketAddress, bob, depositAmount, 30 days);
        
        assertEq(usdt.balanceOf(alice), initialAliceUsdtBalance - depositAmount);
        assertEq(MarketImplementation(marketAddress).balanceOf(bob), initialBobMarketBalance + depositAmount);
        assertEq(MarketImplementation(marketAddress).balanceOf(alice), 0); // Alice should have no market tokens
        
        vm.stopPrank();
    }

    function testDepositAndRedeem() public {
        uint256 depositAmount = 1000;
        uint256 redeemAmount = 500;

        vm.startPrank(alice);
        
        usdt.approve(address(router), depositAmount);
        router.deposit(marketAddress, alice, depositAmount, 30 days);

        skip(30 days);

        uint256 initialMarketBalance = MarketImplementation(marketAddress).balanceOf(alice);
        router.redeem(marketAddress, alice, redeemAmount);
        
        assertEq(MarketImplementation(marketAddress).balanceOf(alice), initialMarketBalance - redeemAmount);
        
        vm.stopPrank();
    }
}
