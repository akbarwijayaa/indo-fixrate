// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { Factory } from "../src/Factory.sol";
import { Market } from "../src/Market.sol";
import { MarketRollover } from "../src/MarketRollover.sol";
import { Router } from "../src/Router.sol";
import { MockUSDT } from "../src/mocks/MockUSDT.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        Market marketImplementation = new Market();
        console.log("Market implementation deployed at:", address(marketImplementation));
        
        Factory factory = new Factory(address(marketImplementation));
        console.log("Factory deployed at:", address(factory));

        Router router = new Router(address(factory));
        console.log("Router deployed at:", address(router));

        MockUSDT usdt = new MockUSDT();
        console.log("MockUSDT deployed at:", address(usdt));

        MarketRollover marketRollover = new MarketRollover();
        console.log("MarketRollover deployed at:", address(marketRollover));
        
        address tokenAccepted = address(usdt);
        string memory name = "Test Market";
        string memory symbol = "TMKT";
        uint256 maxSupply = 1_000_000;
        uint256 maturity = block.timestamp + 365 days;

        factory.createMarket(tokenAccepted, name, symbol, maxSupply, maturity);
        
        vm.stopBroadcast();
    }
}