// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { Router } from "../src/Router.sol";
import { Factory } from "../src/Factory.sol";
import { Market } from "../src/Market.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";

contract RouterDepositTest is Test {
    Router public router;
    Factory public factory;
    Market public marketImplementation;
    MockUSDT public usdt;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public marketAddress;

    function setUp() public {
        usdt = new MockUSDT();
        marketImplementation = new Market();
        factory = new Factory(address(marketImplementation));
        router = new Router(address(factory));

        factory.createMarket(
            address(usdt),
            "Test Market",
            "TMKT",
            1_000_000,
            block.timestamp + 365 days
        );

        marketAddress = factory.markets(0);

        usdt.mint(alice, 10_000);
        usdt.mint(bob, 10_000);
    }

    function testRouterDeposit() public {
        uint256 depositAmount = 1000;

        vm.startPrank(alice);
        usdt.approve(address(router), depositAmount);
        
        uint256 initialUsdtBalance = usdt.balanceOf(alice);
        uint256 initialMarketBalance = Market(marketAddress).balanceOf(alice);
        
        router.deposit(marketAddress, alice, depositAmount);
        
        assertEq(usdt.balanceOf(alice), initialUsdtBalance - depositAmount);
        assertEq(Market(marketAddress).balanceOf(alice), initialMarketBalance + depositAmount);
        
        vm.stopPrank();
    }

    function testRouterRedeem() public {
        uint256 depositAmount = 1000;
        uint256 redeemAmount = 500;

        vm.startPrank(alice);
        
        usdt.approve(address(router), depositAmount);
        router.deposit(marketAddress, alice, depositAmount);
        
        uint256 initialUsdtBalance = usdt.balanceOf(alice);
        uint256 initialMarketBalance = Market(marketAddress).balanceOf(alice);
        
        router.redeem(marketAddress, alice, redeemAmount);
        
        assertEq(usdt.balanceOf(alice), initialUsdtBalance + redeemAmount);
        assertEq(Market(marketAddress).balanceOf(alice), initialMarketBalance - redeemAmount);
        
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
        router.deposit(address(0x123), alice, 1000);
        
        vm.stopPrank();
    }

    function testDepositZeroAmount() public {
        vm.startPrank(alice);
        
        vm.expectRevert(Router.InvalidAmount.selector);
        router.deposit(marketAddress, alice, 0);
        
        vm.stopPrank();
    }

    function testDepositToInactiveMarket() public {
        factory.createMarket(
            address(usdt),
            "Expired Market",
            "EXP",
            1_000_000,
            block.timestamp + 100
        );
        
        address expiredMarketAddress = factory.markets(1);
        
        vm.warp(block.timestamp + 101);
        
        factory.maturedMarket(expiredMarketAddress);
        
        vm.startPrank(alice);
        
        usdt.approve(address(router), 1000);
        
        vm.expectRevert(Router.MarketNotActive.selector);
        router.deposit(expiredMarketAddress, alice, 1000);
        
        vm.stopPrank();
    }

    function testDepositToDifferentRecipient() public {
        uint256 depositAmount = 1000;

        vm.startPrank(alice);
        
        usdt.approve(address(router), depositAmount);
        
        uint256 initialAliceUsdtBalance = usdt.balanceOf(alice);
        uint256 initialBobMarketBalance = Market(marketAddress).balanceOf(bob);
        
        router.deposit(marketAddress, bob, depositAmount);
        
        assertEq(usdt.balanceOf(alice), initialAliceUsdtBalance - depositAmount);
        assertEq(Market(marketAddress).balanceOf(bob), initialBobMarketBalance + depositAmount);
        assertEq(Market(marketAddress).balanceOf(alice), 0); // Alice should have no market tokens
        
        vm.stopPrank();
    }
}
