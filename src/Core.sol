// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

contract Core is ERC20, ERC20Permit, ERC20Votes, Ownable {

    address public immutable tokenAccepted;
    uint256 public immutable maxSupply;
    uint256 public immutable maturity;

    event Deposit(address indexed to, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);

    error TokenNotAccepted(address token);
    error MaxSupplyExceeded(uint256 maxSupply, uint256 attempted);
    error InvalidMaxSupply(uint256 maxSupply);
    error MaturityExceeded();

    constructor(
        address initialTokenAccepted,
        string memory name,
        string memory symbol,
        uint256 maxSupplyAmount,
        uint256 maturityDate
    )
        ERC20(name, symbol)
        ERC20Permit(name)
        Ownable(msg.sender)

    {
        if(maxSupplyAmount == 0) revert InvalidMaxSupply(maxSupplyAmount);

        tokenAccepted = initialTokenAccepted;
        maxSupply = maxSupplyAmount;
        maturity = maturityDate;
    }

    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Votes) {
        if (to != address(0) && numCheckpoints(to) == 0 && delegates(to) == address(0)) {
            _delegate(to, to);
        }
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    function deposit(address to, address tokenIn, uint256 amount) external {
        if (tokenIn != tokenAccepted) revert TokenNotAccepted(tokenIn);
        if (block.timestamp > maturity) revert MaturityExceeded();
        if (totalSupply() + amount > maxSupply) revert MaxSupplyExceeded(maxSupply, totalSupply() + amount);

        IERC20(tokenAccepted).transferFrom(msg.sender, address(this), amount);

        _mint(to, amount);

        

        emit Deposit(to, amount);
    }

    function reedem(address user, uint256 amount) external {
        if (balanceOf(user) < amount) {
            revert("Insufficient balance for redemption");
        }

        _burn(user, amount);
        IERC20(tokenAccepted).transfer(user, amount);

        emit Withdraw(user, amount);
    }
}
