// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import { Reward } from "./Reward.sol";


contract MarketImplementation is Initializable, OwnableUpgradeable {
    address public factory;
    string public marketName;
    address public tokenAccepted;
    uint256 public tvl;
    uint256 public maxSupply;
    uint256 public maturity;
    bool public isActive;

    address public rewardAddress;
    bool public initialized;

    mapping(address => uint256) private balances;
    mapping(address => uint256) public lockPeriods;

    event Deposit(address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);
    event DepositAsOwner(uint256 amount);
    event WithdrawToOwner(address indexed from, address indexed to, uint256 amount);

    error TokenNotAccepted();
    error MaxSupplyExceeded();
    error InvalidMaxSupply();
    error MaturityExceeded();
    error InsufficientBalance();
    error NotMatured();
    error StillLockedPeriod();
    error OnlyFactoryCaller();
    error AlreadyInitialized();
    error ZeroAmount();

    function initialize(
        address owner,
        address _factory,
        string memory _marketName,
        address _tokenAccepted,
        uint256 _maxSupply,
        uint256 _maturity
    ) external initializer {
        __Ownable_init(owner);
        
        if (initialized) revert AlreadyInitialized();
        if(_maxSupply == 0) revert InvalidMaxSupply();

        factory = _factory;
        marketName = _marketName;
        tokenAccepted = _tokenAccepted;
        maxSupply = _maxSupply;
        maturity = _maturity;
        isActive = true;

        rewardAddress = address(new Reward(owner, address(this)));
        initialized = true;

    }

    function deposit(address to, address tokenIn, uint256 amount, uint256 lockPeriod) external {
        if (tokenIn != tokenAccepted) revert TokenNotAccepted();
        if (block.timestamp > maturity) revert MaturityExceeded();
        if (tvl + amount > maxSupply) revert MaxSupplyExceeded();
        

        IERC20(tokenAccepted).transferFrom(msg.sender, address(this), amount);
        Reward(rewardAddress)._updateReward(to);

        lockPeriods[to] = lockPeriod;
        tvl += amount;
        balances[to] += amount;
        emit Deposit(to, amount);
    }

    function redeem(address owner, address to, uint256 amount) external {
        if (balances[owner] < amount) revert InsufficientBalance();
        if (block.timestamp < lockPeriods[owner]) revert StillLockedPeriod();

        balances[owner] -= amount;
        tvl -= amount;

        IERC20(tokenAccepted).transfer(to, amount);
        Reward(rewardAddress)._updateReward(owner);
        emit Withdraw(owner, to, amount);
    }


    function depositAsOwner(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();

        IERC20(tokenAccepted).transferFrom(msg.sender, address(this), amount);
        emit DepositAsOwner(amount);
    }
    

    function redeemToOwner(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        if (amount > IERC20(tokenAccepted).balanceOf(address(this))) revert InsufficientBalance();

        IERC20(tokenAccepted).transfer(msg.sender, amount);
        emit WithdrawToOwner(address(this), msg.sender, amount);
    }

    function isMatured() external view returns (bool) {
        return block.timestamp >= maturity;
    }

    function maturedMarket() external onlyFactory {
        if (!isActive) revert MaturityExceeded();
        if (block.timestamp < maturity) revert NotMatured();

        isActive = false;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactoryCaller();
        _;
    }

}
