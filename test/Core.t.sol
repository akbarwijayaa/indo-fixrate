// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import { Core } from "../src/Core.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";


contract CoreTest is Test {
    Core public core;
    MockUSDT public usdt;

    address public owner = address(0x0);
    address public alice = address(0x1);
    address public bob = address(0x2);

    error MaxSupplyExceeded(uint256 maxSupply, uint256 attempted);

    function setUp() public {
        vm.deal(owner, 1 ether);

        usdt = new MockUSDT();
        core = new Core(address(usdt), "FR-A", "FRA", 1_000_000, block.timestamp + 365 days);

        usdt.mint(alice, 1_000_000);
        usdt.mint(bob, 1_000_000);
    }

    function testDeposit() public {
        vm.startPrank(alice);
        uint256 initialSupply = core.totalSupply();
        usdt.approve(address(core), 100);
        core.deposit(alice, address(usdt), 100);

        assertEq(core.totalSupply(), initialSupply + 100);
    }

    function testRedeem() public {
        vm.startPrank(alice);
        usdt.approve(address(core), 100);
        core.deposit(alice, address(usdt), 100);
        uint256 initialBalance = core.balanceOf(alice);

        core.reedem(alice, 50);
        assertEq(core.balanceOf(alice), initialBalance - 50);
    }

    function testMaxSupplyExceeded() public {
        // vm.expectRevert();
        vm.startPrank(alice);
        usdt.approve(address(core), 2_000_000);
        vm.expectRevert();
        core.deposit(alice, address(usdt), 2_000_000);
    }


    function testGetVotes() public {
        vm.startPrank(alice);
        usdt.approve(address(core), 100);
        core.deposit(alice, address(usdt), 100);

        uint256 votes = core.getVotes(alice);
        console.log("Votes for Alice: %s", votes);
    }   
}