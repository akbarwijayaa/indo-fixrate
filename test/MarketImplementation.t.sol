// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { MarketImplementation } from "../src/MarketImplementation.sol";
import { Factory } from "../src/Factory.sol";
import { MarketProxy } from "../src/Proxy.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract MarketImplementationTest is Test {
    MarketImplementation public market;
    MarketImplementation public marketImplementation;
    Factory public factory;
    MockUSDT public usdt;

    address public owner = address(0x123);
    address public alice = address(0x1);
    address public bob = address(0x2);

    error MaxSupplyExceeded(uint256 maxSupply, uint256 attempted);

    function setUp() public {
        vm.deal(owner, 1 ether);

        usdt = new MockUSDT();
        
        vm.startPrank(owner);

        marketImplementation = new MarketImplementation();
        
        // Deploy factory with market implementation
        factory = new Factory(address(marketImplementation));
        
        // Create market through factory
        factory.createMarket(
            "FR-A",
            address(usdt),
            1_000_000,
            block.timestamp + 365 days
        );
        
        // Get the created market proxy
        address marketAddress = factory.markets(0);
        market = MarketImplementation(marketAddress);

        vm.stopPrank();

        usdt.mint(alice, 1_000_000);
        usdt.mint(bob, 1_000_000);
    }

    function testDeposit() public {
        vm.startPrank(alice);
        uint256 initialSupply = market.tvl();
        usdt.approve(address(market), 100);
        market.deposit(alice, address(usdt), 100, block.timestamp + 30 days);

        assertEq(market.tvl(), initialSupply + 100);
        assertEq(market.balanceOf(alice), 100);
    }

    function testRedeem() public {
        vm.startPrank(alice);
        usdt.approve(address(market), 100);
        market.deposit(alice, address(usdt), 100, block.timestamp + 30 days);
        uint256 initialBalance = market.balanceOf(alice);

        skip(30 days);

        market.redeem(alice, alice, 50);
        assertEq(market.balanceOf(alice), initialBalance - 50);
    }

    function testMaxSupplyExceeded() public {
        vm.startPrank(alice);
        usdt.approve(address(market), 2_000_000);
        vm.expectRevert();
        market.deposit(alice, address(usdt), 2_000_000, block.timestamp + 30 days);
    }

    function testMaturedMarket() public {
        skip(365 days);
        vm.expectRevert();
        market.maturedMarket();
    }


}
