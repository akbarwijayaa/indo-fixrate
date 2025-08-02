// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { IReward} from "./interfaces/IReward.sol";
import { IFactory } from "./interfaces/IFactory.sol";

contract Router {
    address public immutable factory;

    event Deposit(address indexed to, uint256 amount);
    event Redeem(address indexed from, address indexed to, uint256 amount);

    error NotMatured();
    error MarketNotFound();
    error MarketNotActive();
    error InvalidAmount();

    constructor(address _factory) {
        factory = _factory;
    }

    function maturedMarket(address marketAddress) external {
        if (block.timestamp < IMarket(marketAddress).maturity()) revert NotMatured();

        IMarket(marketAddress).maturedMarket();
    }


    function getActiveMarkets() external view returns (address[] memory) {
        uint256 len = IFactory(factory).getMarketsLength();
        uint256 count;

        for (uint256 i; i < len; ++i) {
            if (IMarket(IFactory(factory).markets(i)).isActive()) count++;
        }

        address[] memory result = new address[](count);
        uint256 idx;

        for (uint256 i; i < len; ++i) {
            if (IMarket(IFactory(factory).markets(i)).isActive()) {
                result[idx] = IFactory(factory).markets(i);
                unchecked { ++idx; }
            }
        }
        return result;
    }

    /**
     * @notice Deposit tokens into a specific market
     * @param marketAddress The address of the market to deposit into
     * @param to The recipient address for the market tokens
     * @param amount The amount of tokens to deposit
     */
    function deposit(address marketAddress, address to, uint256 amount, uint256 lockPeriod) external {
        if (amount == 0) revert InvalidAmount();
        if (!_isValidMarket(marketAddress)) revert MarketNotFound();
        if (!IMarket(marketAddress).isActive()) revert MarketNotActive();

        address tokenAccepted = IMarket(marketAddress).tokenAccepted();
        IERC20(tokenAccepted).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenAccepted).approve(marketAddress, amount);

        IMarket(marketAddress).deposit(to, tokenAccepted, amount, lockPeriod);

        emit Deposit(to, amount);
    }

    /**
     * @notice Redeem tokens from a specific market
     * @param marketAddress The address of the market to redeem from
     * @param to The recipient address for the underlying tokens
     * @param amount The amount of market tokens to redeem
     */
    function redeem(address marketAddress, address to, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (!_isValidMarket(marketAddress)) revert MarketNotFound();

        IMarket(marketAddress).redeem(msg.sender, to, amount);

        emit Redeem(msg.sender, to, amount);
    }

    /**
     * @notice Get market information
     * @param marketAddress The address of the market
     * @return tokenAccepted The token accepted by the market
     * @return maxSupply Maximum supply of the market
     * @return maturity Maturity timestamp
     * @return isActive Whether the market is active
     */
    function getMarketInfo(address marketAddress) external view returns (
        address tokenAccepted,
        uint256 maxSupply,
        uint256 maturity,
        bool isActive
    ) {
        if (!_isValidMarket(marketAddress)) revert MarketNotFound();
        
        tokenAccepted = IMarket(marketAddress).tokenAccepted();
        maxSupply = IMarket(marketAddress).maxSupply();
        maturity = IMarket(marketAddress).maturity();
        isActive = IMarket(marketAddress).isActive();
    }

    /**
     * @notice Check if an address is a valid market created by the factory
     * @param marketAddress The address to check
     * @return isValid True if the address is a valid market
     */
    function _isValidMarket(address marketAddress) internal view returns (bool isValid) {
        uint256 len = IFactory(factory).getMarketsLength();
        
        for (uint256 i; i < len; ++i) {
            if (IFactory(factory).markets(i) == marketAddress) {
                return true;
            }
        }
        
        return false;
    }
}
