// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

interface IMarket {
    function deposit(address to, address tokenIn, uint256 amount) external;
    function redeem(address owner, address to, uint256 amount) external;
    function isMatured() external view returns (bool);
    function maturedMarket() external;
    function factory() external view returns (address);
    function tokenAccepted() external view returns (address);
    function maxSupply() external view returns (uint256);
    function maturity() external view returns (uint256);
    function isActive() external view returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}
