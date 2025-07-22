// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Market } from "./Market.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MarketRollover {

    event MarketRolledOver(address indexed oldMarket, address indexed newMarket, uint256 amount);

    error InvalidMarketAddress();
    error InvalidAmount();
    error MarketNotMatured();

    function rollover(
        address oldMarketAddr,
        address newMarketAddr,
        uint256 amount
    ) external {
        if (oldMarketAddr == address(0) && newMarketAddr == address(0)) revert InvalidMarketAddress();
        if (amount == 0) revert InvalidAmount();

        Market oldMarket = Market(oldMarketAddr);
        Market newMarket = Market(newMarketAddr);

        if (!oldMarket.isMatured()) revert MarketNotMatured();
        oldMarket.redeem(msg.sender, address(this), amount);

        IERC20(oldMarket.tokenAccepted()).approve(newMarketAddr, amount);
        newMarket.deposit(msg.sender, address(oldMarket.tokenAccepted()), amount);

        emit MarketRolledOver(oldMarketAddr, newMarketAddr, amount);
    }
}