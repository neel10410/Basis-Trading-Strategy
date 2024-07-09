// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Adapter} from "./adapter.sol";
import "forge-std/console.sol";

contract Vault {
    Adapter public adapter;
    IERC20 public immutable usdcToken;

    uint256 public totalSupply;
    uint96 size;

    mapping(address => uint256) public balanceOf;

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
    }

    function _mint(address _to, uint256 lpToken) private {
        totalSupply += lpToken;
        balanceOf[_to] += lpToken;
    }

    function _burn(address _from, uint256 lpToken) private {
        totalSupply -= lpToken;
        balanceOf[_from] -= lpToken;
    }

    function deposit(uint96 collateralAmount) external {
        uint256 _lpToken;
        if (totalSupply == 0) {
            _lpToken = collateralAmount;
        } else {
            _lpToken = (collateralAmount * totalSupply) / totalSupply;
        }

        _mint(msg.sender, _lpToken);
        usdcToken.transferFrom(msg.sender, address(this), collateralAmount);
        console.log("here");

        size = collateralAmount / 2;
        console.log(size);
        adapter.openShortPosition(size);
        console.log("here");

        adapter.buyInSpot(size);
    }

    function withdraw(uint256 lpToken) external {
        // change it
        uint256 amount = (lpToken * usdcToken.balanceOf(address(this))) /
            totalSupply;
        _burn(msg.sender, lpToken);
        usdcToken.transfer(msg.sender, amount);
        adapter.closeShortPosition(size);
        adapter.sellInSpot();
    }
}
