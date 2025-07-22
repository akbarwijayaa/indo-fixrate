// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

interface IFactory {
    function createMarket(
        address tokenAccepted,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 maturity
    ) external;

    function markets(uint256 index) external view returns (address);
    function getMarketsLength() external view returns (uint256);
}
