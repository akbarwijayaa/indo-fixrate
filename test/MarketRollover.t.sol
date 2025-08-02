// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { MarketRollover } from "../src/MarketRollover.sol";
import { MarketImplementation } from "../src/MarketImplementation.sol";
import { Factory } from "../src/Factory.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract MarketRolloverTest is Test {
    MarketImplementation public market;
    MarketImplementation public marketImplementation;
    MockUSDT public usdt;
    MarketRollover public marketRollover;
    Factory public factory;
    address public alice = address(0x1);

    function setUp() public {
        usdt = new MockUSDT();
        
        marketImplementation = new MarketImplementation();
        factory = new Factory(address(marketImplementation));
        
        factory.createMarket(
            "Test Market",
            address(usdt),
            1_000_000,
            block.timestamp + 365 days
        );
        
        address marketAddress = factory.markets(0);
        market = MarketImplementation(marketAddress);
        
        marketRollover = new MarketRollover();

        usdt.mint(alice, 1_000_000);
    }

    function testRollover() public {
        address oldMarketAddr = address(market);

        vm.startPrank(alice);
        usdt.approve(oldMarketAddr, 1000);
        market.deposit(alice, address(usdt), 1000, 365 days);
        vm.stopPrank();
        
        skip(365 days);

        // Create new market through factory for rollover (as owner, not alice)
        factory.createMarket(
            "New Market",
            address(usdt),
            1_000_000,
            block.timestamp + 365 days
        );

        address newMarketAddress = factory.markets(1);

        vm.startPrank(alice);
        marketRollover.rollover(oldMarketAddr, newMarketAddress, 1000, 30 days);

        assertEq(usdt.balanceOf(newMarketAddress), 1000);
        assertEq(market.balanceOf(alice), 0);
        
        vm.stopPrank();
    }

    function testRolloverWithNonMaturedMarket() public {
        address oldMarketAddr = address(market);
        
        // Create new market through factory for rollover
        factory.createMarket(
            "New Market",
            address(usdt),
            1_000_000,
            block.timestamp + 365 days
        );

        address newMarketAddress = factory.markets(1);

        vm.startPrank(alice);
        usdt.approve(oldMarketAddr, 1000);
        market.deposit(alice, address(usdt), 1000, 30 days);

        vm.expectRevert(MarketRollover.MarketNotMatured.selector);
        marketRollover.rollover(oldMarketAddr, newMarketAddress, 1000, 30 days);

        vm.stopPrank();
    }
}