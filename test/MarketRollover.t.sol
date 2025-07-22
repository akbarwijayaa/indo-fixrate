// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { MarketRollover } from "../src/MarketRollover.sol";
import { Market } from "../src/Market.sol";
import { Factory } from "../src/Factory.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract MarketRolloverTest is Test {
    Market public market;
    Market public marketImplementation;
    MockUSDT public usdt;
    MarketRollover public marketRollover;
    Factory public factory;
    address public alice = address(0x1);

    function setUp() public {
        usdt = new MockUSDT();
        
        // Deploy market implementation
        marketImplementation = new Market();
        
        // Deploy factory with market implementation
        factory = new Factory(address(marketImplementation));
        
        // Create market through factory
        factory.createMarket(
            address(usdt),
            "Test Market",
            "TMKT",
            1_000_000,
            block.timestamp + 365 days
        );
        
        // Get the created market proxy
        address marketAddress = factory.markets(0);
        market = Market(marketAddress);
        
        marketRollover = new MarketRollover();

        usdt.mint(alice, 1_000_000);
    }

    function testRollover() public {
        address oldMarketAddr = address(market);

        vm.startPrank(alice);
        usdt.approve(oldMarketAddr, 1000);
        market.deposit(alice, address(usdt), 1000);
       
        vm.warp(block.timestamp + 366 days);
        vm.stopPrank();

        // Create new market through factory for rollover (as owner, not alice)
        factory.createMarket(
            address(usdt),
            "New Market",
            "NWMKT",
            1_000_000,
            block.timestamp + 365 days
        );

        address newMarketAddress = factory.markets(1);

        vm.startPrank(alice);
        marketRollover.rollover(oldMarketAddr, newMarketAddress, 1000);

        assertEq(usdt.balanceOf(newMarketAddress), 1000);
        assertEq(market.balanceOf(alice), 0);
        
        vm.stopPrank();
    }

    function testRolloverWithNonMaturedMarket() public {
        address oldMarketAddr = address(market);
        
        // Create new market through factory for rollover
        factory.createMarket(
            address(usdt),
            "New Market",
            "NWMKT",
            1_000_000,
            block.timestamp + 365 days
        );

        address newMarketAddress = factory.markets(1);

        vm.startPrank(alice);
        usdt.approve(oldMarketAddr, 1000);
        market.deposit(alice, address(usdt), 1000);

        vm.expectRevert(MarketRollover.MarketNotMatured.selector);
        marketRollover.rollover(oldMarketAddr, newMarketAddress, 1000);

        vm.stopPrank();
    }
}