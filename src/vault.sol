// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {adapter} from "./adapter.sol";

contract Vault {
    IERC20 public immutable usdcTokenToken;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _usdcTokenToken) {
        usdcTokenToken = IERC20(_usdcTokenToken);
    }

    function _mint(address _to, uint256 _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint256 _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint256 _amount) external {
        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares =
                (_amount * totalSupply) /
                usdcToken.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        usdcToken.transferFrom(msg.sender, address(this), _amount);
        Adapter.openShortPosition();
        Adapter.buyInSpot();
    }

    function withdraw(uint256 _shares) external {
        uint256 amount = (_shares * usdcToken.balanceOf(address(this))) /
            totalSupply;
        _burn(msg.sender, _shares);
        usdcToken.transfer(msg.sender, amount);
        Adapter.closeShortPosition();
        Adapter.sellInSpot();
    }
}
