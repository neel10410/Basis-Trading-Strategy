// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {adapter} from "./adapter.sol";

contract Vault {
    IERC20 public immutable usdcTokenToken;

    uint256 public totalSupply;
    uint96 size;
    uint8 collateralId = 0;
    uint8 assetId = 3;
    uint8 IsLong = 0;
    uint72 Zero = 0x000000000000000000;
    bytes32 subAccountId =
        bytes32(
            abi.encodePacked(address(this), collateralId, assetId, IsLong, Zero)
        );
    PositionOrderExtra memory positionOrderExtra;
    PositionOrderExtra.tpPrice = 0;
    PositionOrderExtra.slPrice = 0;
    PositionOrderExtra.tpslProfitTokenId = 0;
    PositionOrderExtra.tpslDeadline = 1694943857;

    mapping(address => uint256) public balanceOf;

    constructor(address _usdcTokenToken) {
        usdcTokenToken = IERC20(_usdcTokenToken);
    }

    function _mint(address _to, uint256 lpToken) private {
        totalSupply += lpToken;
        balanceOf[_to] += lpToken;
    }

    function _burn(address _from, uint256 lpToken) private {
        totalSupply -= lpToken;
        balanceOf[_from] -= lpToken;
    }

    function deposit(uint256 collateralAmount) external {
        uint256 _lpToken;
        if (totalSupply == 0) {
            _lpToken = collateralAmount;
        } else {
            _lpToken = (collateralAmount * totalSupply) / totalSupply;
        }

        _mint(msg.sender, _lpToken);
        usdcToken.transferFrom(msg.sender, address(this), collateralAmount);

        size = collateralAmount / 2;
        Adapter.openShortPosition(
            subAccountId,
            size,
            size,
            0,
            0,
            192,
            0,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            positionOrderExtra
        );
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address[] path = [address(usdcTokenToken), weth];
        uint256 deadline = block.timestamp + 86400;
        // change amount min
        Adapter.buyInSpot(size, 1, path, msg.sender, deadline);
    }

    function withdraw(uint256 lpToken) external {
        // change it
        uint256 amount = (lpToken * usdcToken.balanceOf(address(this))) /
            totalSupply;
        _burn(msg.sender, lpToken);
        usdcToken.transfer(msg.sender, amount);
        Adapter.closeShortPosition(
            subAccountId,
            0,
            size,
            0,
            0,
            96,
            0,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            positionOrderExtra
        );
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address[] path = [weth, address(usdcTokenToken)];
        uint256 deadline = block.timestamp + 86400;
        // change amount min
        Adapter.sellInSpot(1, path, msg.sender, deadline);
    }
}
