// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Test, console } from "forge-std/Test.sol";
import { Factory } from "../src/Factory.sol";
import { Market } from "../src/Market.sol";
import { Proxy } from "../src/Proxy.sol";

contract ProxyTest is Test {
    Factory factory;
    Market market;

    function setUp() public {
        market = new Market();
        factory = new Factory(address(market));
    }

    function testCreateMarket() public {
        factory.createMarket(
            address(0x123),
            "Test Market",
            "TMKT",
            1000 ether,
            block.timestamp + 30 days
        );
        address proxyAddr = factory.markets(0);

        // Panggil via proxy
        Market proxy = Market(proxyAddr);
        assertEq(proxy.tokenAccepted(), address(0x123));
    }
}
