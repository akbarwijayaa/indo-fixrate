// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Test, console } from "forge-std/Test.sol";
import { Factory } from "../src/Factory.sol";
import { MarketImplementation } from "../src/MarketImplementation.sol";

contract MarketTest is Test {
    Factory factory;
    MarketImplementation market;

    function setUp() public {
        market = new MarketImplementation();
        factory = new Factory(address(market));
    }

    function testCreateMarket() public {
        factory.createMarket(
            "Test Market",
            address(0x123),
            1000 ether,
            block.timestamp + 30 days
        );
        address proxyAddr = factory.markets(0);

        // Panggil via proxy
        MarketImplementation proxy = MarketImplementation(proxyAddr);
        assertEq(proxy.tokenAccepted(), address(0x123));
    }
}
