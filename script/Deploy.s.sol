// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Factory} from "../src/Factory.sol";
import {MockUSDT} from "../src/mocks/MockUSDT.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        
        Factory factory = new Factory();
        MockUSDT usdt = new MockUSDT();
        
        address tokenAccepted = address(usdt);
        string memory name = "Test Market";
        string memory symbol = "TMKT";
        uint256 maxSupply = 1_000_000;
        uint256 maturity = block.timestamp + 365 days;

        factory.createMarket(tokenAccepted, name, symbol, maxSupply, maturity);
        
        vm.stopBroadcast();
    }
}