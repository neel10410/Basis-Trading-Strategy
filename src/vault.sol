// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquidityPool, Asset, IChainlinkV2V3} from "../src/interfaces/IMux.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Adapter} from "./adapter.sol";
import "forge-std/console.sol";

contract Vault is ERC20 {
    Adapter public adapter;
    IERC20 public immutable usdcToken;
    uint256 totalShortPosition;

    constructor(address _usdcToken) ERC20("lpToken", "lp") {
        usdcToken = IERC20(_usdcToken);
    }

    function setAdapter(address payable adapterAddress) external {
        adapter = Adapter(adapterAddress);
    }

    function updateFunding() private {
        (
            uint96 collateral,
            uint96 size,
            uint32 lastIncreasedTime,
            uint96 entryPrice,
            uint128 entryFunding
        ) = adapter.getPosition();

        Asset memory asset = adapter.getAssetInfo(3);

        uint fundingAmount = (asset.shortCumulativeFunding - entryFunding) *
            size;

        // console.log("funding amount", fundingAmount);

        // uint netValue = ; // find a way to get it
        // uint currentPrice = adapter.getAssetPrice(3);
        // uint fundingAmount = collateral -
        //     (size * ((2 * entryPrice) - currentPrice));

        adapter.closeShortPosition(uint96(fundingAmount));
    }

    function mint(address _to, uint256 lpToken) private {
        _mint(_to, lpToken);
    }

    function burn(address _from, uint256 lpToken) private {
        _burn(_from, lpToken);
    }

    function deposit(uint96 collateralAmount) external {
        uint256 _lpToken;
        if (totalSupply() == 0) {
            mint(address(0), 100);
            _lpToken = collateralAmount;
        } else {
            _lpToken =
                (collateralAmount * totalSupply()) /
                usdcToken.balanceOf(address(adapter));
        }

        mint(msg.sender, _lpToken);
        usdcToken.transferFrom(msg.sender, address(adapter), collateralAmount);
        // console.log(
        //     "usdc bal of adapter",
        //     usdcToken.balanceOf(address(adapter))
        // );

        // updateFunding();
        uint96 size = collateralAmount / 2;
        adapter.openShortPosition(size);

        adapter.buyInSpot(size);
    }

    function withdraw(uint256 lpToken) external {
        // change it
        uint256 sharePercentage = (lpToken * 100) / totalSupply();

        burn(msg.sender, lpToken);
        // console.log("share percentage", sharePercentage);
        // console.log("total short", totalShortPosition);

        updateFunding();
        uint256 closePartialPosition = (totalShortPosition * sharePercentage) /
            100;
        // // console.log("partial close plsotion", closePartialPosition);
        // // console.log(
        //     "balance of usdc before close postion",
        //     usdcToken.balanceOf(address(adapter))
        // );
        adapter.closeShortPosition(uint96(closePartialPosition));
        // console.log(
        //     "balance of usdc after close postion",
        //     usdcToken.balanceOf(address(adapter))
        // );
        uint256 ethAmountToSell = ((address(adapter).balance) *
            sharePercentage) / 100;
        // console.log(
        //     "adapter balance of eth before swap",
        //     (address(adapter).balance)
        // );
        // console.log("eth amount to sell", ethAmountToSell);
        adapter.sellInSpot(ethAmountToSell);
        // console.log(
        //     "adapter balance of eth after swap",
        //     (address(adapter).balance)
        // );
        // console.log(
        //     "balance of usdc after swap",
        //     usdcToken.balanceOf(address(adapter))
        // );
    }
}
