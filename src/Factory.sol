// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Core } from "./Core.sol";
import { Reward } from "./Reward.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract Factory is Ownable {
    Core public coreContract;
    Reward public rewardContract;

    event MarketCreated(address indexed marketAddress);

    error InvalidTokenAddress(address token);
    error InvalidMaxSupply(uint256 maxSupply);
    error InvalidMaturity(uint256 maturity);
    error InvalidNameOrSymbol(string name, string symbol);
    
    constructor() Ownable(msg.sender) {}

    function createMarket (
        address tokenAccepted,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 maturity
    ) external onlyOwner {
        if (tokenAccepted == address(0)) revert InvalidTokenAddress(tokenAccepted);
        if (maxSupply == 0) revert InvalidMaxSupply(maxSupply);
        if (maturity <= block.timestamp) revert InvalidMaturity(maturity);
        if (bytes(name).length == 0 || bytes(symbol).length == 0) revert InvalidNameOrSymbol(name, symbol);

        coreContract = new Core(tokenAccepted, name, symbol, maxSupply, maturity);
        rewardContract = new Reward(tokenAccepted, name, symbol, maxSupply, maturity);

        emit MarketCreated(address(coreContract));
    }
}