// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { MarketProxy } from "./Proxy.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract Factory is Ownable {
    address public immutable marketImplementation;
    address[] public markets;

    event MarketCreated(
        address indexed marketAddress,
        address indexed tokenAccepted,
        uint256 maxSupply,
        uint256 maturity
    );

    error ZeroAddress();
    error ZeroMaxSupply();
    error InvalidMaturity();
    error InvalidName();
    error NotMatured();

    constructor(address _marketImplementation) Ownable(address(msg.sender)) {
        marketImplementation = _marketImplementation;
    }

    function createMarket (
        string memory name,
        address tokenAccepted,
        uint256 maxSupply,
        uint256 maturity
    ) external onlyOwner {
        if (bytes(name).length == 0) revert InvalidName();
        if (tokenAccepted == address(0)) revert ZeroAddress();
        if (maxSupply == 0) revert ZeroMaxSupply();
        if (maturity <= block.timestamp) revert InvalidMaturity();

        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,string,address,uint256,uint256)",
            address(msg.sender),
            address(this),
            name,
            tokenAccepted,
            maxSupply,
            maturity
        );

        MarketProxy market = new MarketProxy(marketImplementation, initData);

        markets.push(address(market));

        emit MarketCreated(address(market), tokenAccepted, maxSupply, maturity);
    }

    function maturedMarket(address marketAddress) external onlyOwner {
        if (block.timestamp < IMarket(marketAddress).maturity()) revert NotMatured();

        IMarket(marketAddress).maturedMarket();
    }


    function getMarketsLength() external view returns (uint256) {
        return markets.length;
    }

    function getActiveMarkets() external view returns (address[] memory) {
        uint256 len = markets.length;
        uint256 count;

        for (uint256 i; i < len; ++i) {
            if (IMarket(markets[i]).isActive()) count++;
        }

        address[] memory result = new address[](count);
        uint256 idx;

        for (uint256 i; i < len; ++i) {
            if (IMarket(markets[i]).isActive()) {
                result[idx] = markets[i];
                unchecked { ++idx; }
            }
        }
        return result;
    }
}