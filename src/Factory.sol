// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Proxy } from "./Proxy.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract Factory is Ownable {
    address public immutable marketImplementation;
    address[] public markets;

    event MarketCreated(
      address indexed tokenAccepted,
      string name,
      string symbol,
      uint256 maxSupply,
      uint256 maturity
    );

    error ZeroAddress();
    error ZeroMaxSupply();
    error InvalidMaturity();
    error EmptyString();
    error NotMatured();

    constructor(address _marketImplementation) Ownable(msg.sender) {
        marketImplementation = _marketImplementation;
    }

    function createMarket (
        address tokenAccepted,
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 maturity
    ) external onlyOwner {
        if (tokenAccepted == address(0)) revert ZeroAddress();
        if (maxSupply == 0) revert ZeroMaxSupply();
        if (maturity <= block.timestamp) revert InvalidMaturity();
        if (bytes(name).length == 0 || bytes(symbol).length == 0) revert EmptyString();

        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,string,string,uint256,uint256)",
            address(this),
            tokenAccepted,
            name,
            symbol,
            maxSupply,
            maturity
        );

        Proxy market = new Proxy(marketImplementation, initData);

        markets.push(address(market));

        emit MarketCreated(tokenAccepted, name, symbol, maxSupply, maturity);
    }

    function maturedMarket(address marketAddress) external {
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