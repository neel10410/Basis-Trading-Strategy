// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router.sol";
import {IOrderBook} from "./interfaces/IOrderBook.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquidityPool, Asset, IChainlinkV2V3} from "../src/interfaces/IMux.sol";
import "forge-std/console.sol";

contract Adapter {
    IUniswapV2Router02 public uniswapV2Router; // Uniswap
    IOrderBook public orderBook; // MUX
    ILiquidityPool LiquidityPool; // MUX

    IERC20 public immutable usdcToken =
        IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    uint8 collateralId = 0;
    uint8 assetId = 3;
    uint8 IsLong = 0;
    uint72 Zero = 0x000000000000000000;
    bytes32 subAccountId =
        bytes32(
            abi.encodePacked(address(this), collateralId, assetId, IsLong, Zero)
        );
    IOrderBook.PositionOrderExtra positionOrderExtra;
    mapping(address => uint256) public userEthHolding;

    constructor(
        IUniswapV2Router02 _uniswapV2Router,
        IOrderBook _orderBook,
        ILiquidityPool _LiquidityPool
    ) {
        uniswapV2Router = _uniswapV2Router;
        orderBook = _orderBook;
        LiquidityPool = _LiquidityPool;
    }

    fallback() external payable {}
    receive() external payable {}

    function getAssetPrice(uint8 _assetId) public view returns (uint) {
        Asset memory asset = LiquidityPool.getAssetInfo(_assetId);
        uint price = _readChainlink(asset.referenceOracle);
        return price;
    }
    function _readChainlink(
        address referenceOracle
    ) internal view returns (uint96) {
        int256 ref = IChainlinkV2V3(referenceOracle).latestAnswer();
        require(ref > 0, "P=0");
        ref *= 1e10;
        return uint96(uint256(ref));
    }

    function openShortPosition(uint96 size) external {
        console.logBytes32(subAccountId);
        positionOrderExtra.tpPrice = 0;
        positionOrderExtra.slPrice = 0;
        positionOrderExtra.tpslProfitTokenId = 0;
        positionOrderExtra.tpslDeadline = uint32(block.timestamp + 2629743); // + 1 Month

        console.log("size", size);
        uint256 price = getAssetPrice(assetId);
        console.log("price", price);
        uint96 sizeInWei = uint96(((size * 1e18) / price) * 1e12);
        console.log("size in wei", sizeInWei);

        uint bal1 = usdcToken.balanceOf(address(this));
        console.log("bal of usdc Before open position", bal1);

        usdcToken.approve(address(orderBook), type(uint256).max);

        orderBook.placePositionOrder3(
            subAccountId,
            size,
            sizeInWei,
            0,
            0,
            192,
            0,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            positionOrderExtra
        );

        uint bal2 = usdcToken.balanceOf(address(this));
        console.log("bal of usdc after open position", bal2);

        // usdcToken.approve(address(orderBook), type(uint256).max);
        // orderBook.placePositionOrder3(
        //     subAccountId,
        //     804660000,
        //     1303700000000000000,
        //     0,
        //     0,
        //     192,
        //     0,
        //     0x0000000000000000000000000000000000000000000000000000000000000000,
        //     positionOrderExtra
        // );
    }

    function closeShortPosition(uint96 size) external {
        positionOrderExtra.tpPrice = 0;
        positionOrderExtra.slPrice = 0;
        positionOrderExtra.tpslProfitTokenId = 3;
        positionOrderExtra.tpslDeadline = uint32(block.timestamp + 2629743); // + 1 Month
        orderBook.placePositionOrder3(
            subAccountId,
            0,
            size,
            0,
            3,
            96,
            0,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            positionOrderExtra
        );
    }

    function buyInSpot(uint256 size) external {
        address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = weth;
        uint256 deadline = (1752281914);
        usdcToken.approve(address(uniswapV2Router), type(uint256).max);

        // uint256 sizeInWei = size * 1e12;
        // change amount min
        uniswapV2Router.swapExactTokensForETH(
            size,
            0,
            path,
            address(this),
            deadline
        );
        uint ethBal = address(this).balance;
        console.log("eth bal of adapter after swap", ethBal);
    }

    function sellInSpot(uint256 size) external {
        address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdc;
        uint256 deadline = block.timestamp + 2629743;
        // change amount min
        uniswapV2Router.swapExactETHForTokens{value: size}(
            0,
            path,
            address(this),
            deadline
        ); // {value: ?}
    }
}
