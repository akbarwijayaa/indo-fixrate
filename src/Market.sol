// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import { Reward } from "./Reward.sol";


contract Market is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    address public factory;
    address public tokenAccepted;
    uint256 public maxSupply;
    uint256 public maturity;  
    bool public isActive;

    address public rewardAddress;
    bool public initialized;

    event Deposit(address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);

    error TokenNotAccepted();
    error MaxSupplyExceeded();
    error InvalidMaxSupply();
    error MaturityExceeded();
    error InsufficientBalance();
    error NotMatured();
    error OnlyFactoryCaller();
    error AlreadyInitialized();

    function initialize(
        address _factory,
        address initialTokenAccepted,
        string memory name,
        string memory symbol,
        uint256 maxSupplyAmount,
        uint256 maturityDate
    ) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        
        if (initialized) revert AlreadyInitialized();
        if(maxSupplyAmount == 0) revert InvalidMaxSupply();

        factory = _factory;
        tokenAccepted = initialTokenAccepted;
        maxSupply = maxSupplyAmount;
        maturity = maturityDate;
        isActive = true;

        rewardAddress = address(new Reward(address(this)));
        initialized = true;
    }


    function deposit(address to, address tokenIn, uint256 amount) external {
        if (tokenIn != tokenAccepted) revert TokenNotAccepted();
        if (block.timestamp > maturity) revert MaturityExceeded();
        if (totalSupply() + amount > maxSupply) revert MaxSupplyExceeded();

        IERC20(tokenAccepted).transferFrom(msg.sender, address(this), amount);
        Reward(rewardAddress)._updateReward(to);
        _mint(to, amount);

        emit Deposit(to, amount);
    }

    function redeem(address owner, address to, uint256 amount) external {
        if (balanceOf(owner) < amount) revert InsufficientBalance();

        _burn(owner, amount);
        IERC20(tokenAccepted).transfer(to, amount);
        Reward(rewardAddress)._updateReward(owner);
        emit Withdraw(owner, to, amount);
    }

    function isMatured() external view returns (bool) {
        return block.timestamp >= maturity;
    }

    function maturedMarket() external onlyOwner {
        if (!isActive) revert MaturityExceeded();
        if (block.timestamp < maturity) revert NotMatured();

        isActive = false;
    }
}
