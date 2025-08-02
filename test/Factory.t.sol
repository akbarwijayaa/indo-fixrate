// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { Factory } from "../src/Factory.sol";
import { MarketImplementation } from "../src/MarketImplementation.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";
import { Router } from "../src/Router.sol";


contract FactoryTest is Test {
    Factory public factory;
    MarketImplementation public marketImplementation;
    Router public router;
    MockUSDT public usdt;

    address public owner = address(0x0);
    address public tokenAccepted;

    string public name = "Test Market";
    string public symbol = "TMKT";
    uint256 public maxSupply = 1_000_000;
    uint256 public maturity = block.timestamp + 365 days;

    function setUp() public {
        vm.deal(owner, 1 ether);
        usdt = new MockUSDT();
        tokenAccepted = address(usdt);
        
        marketImplementation = new MarketImplementation();
        factory = new Factory(address(marketImplementation));
        router = new Router(address(factory));
    }

    function testCreateMarket() public {
        factory.createMarket(name, tokenAccepted, maxSupply, maturity);

        assertEq(factory.markets(0), address(router.getActiveMarkets()[0]));
    }

    function testGetActiveMarkets() public {
        factory.createMarket(name, tokenAccepted, maxSupply, maturity);
        factory.createMarket(name, tokenAccepted, maxSupply, maturity);
        address[] memory activeMarkets = router.getActiveMarkets();

        assertEq(activeMarkets.length, 2);
    }

    function testDeactivateMarketAndCheckActiveMarket() public {
        factory.createMarket(name, tokenAccepted, maxSupply, maturity);
        vm.warp(block.timestamp + 365 days);
        factory.maturedMarket(factory.markets(0));
        address[] memory activeMarkets = router.getActiveMarkets();

        assertEq(activeMarkets.length, 0);
    }

    function testNonAutorizedCreateMarket() public {
        vm.startPrank(address(owner));
        vm.expectRevert();
        factory.createMarket(name, tokenAccepted, maxSupply, maturity);
        vm.stopPrank();
    }

    function testInvalidTokenAddress() public {
        vm.expectRevert();
        factory.createMarket(name, address(0), maxSupply, maturity);
    }

    function testInvalidMaxSupply() public {
        vm.expectRevert();
        factory.createMarket(name, tokenAccepted, 0, maturity);
    }

    function testInvalidMaturity() public {
        vm.expectRevert();
        factory.createMarket(name, tokenAccepted, maxSupply, block.timestamp);
    }

    function testInvalidNameOrSymbol() public {
        vm.expectRevert();
        factory.createMarket("", tokenAccepted, maxSupply, maturity);
    }
}