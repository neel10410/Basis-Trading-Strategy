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

    function getAssetPrice(uint8 _assetId) internal view returns (uint) {
        console.log("here1");

        Asset memory asset = LiquidityPool.getAssetInfo(_assetId);
        console.log("here2");

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

        uint256 price = getAssetPrice(assetId);
        console.log(price);
        uint96 sizeInWei = uint96((size / price) * 10e18);

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
    }

    function closeShortPosition(uint96 size) external {
        positionOrderExtra.tpPrice = 0;
        positionOrderExtra.slPrice = 0;
        positionOrderExtra.tpslProfitTokenId = 0;
        positionOrderExtra.tpslDeadline = uint32(block.timestamp + 2629743); // + 1 Month
        orderBook.placePositionOrder3(
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
    }

    function buyInSpot(uint256 size) external {
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = weth;
        uint256 deadline = block.timestamp + 86400;
        // change amount min
        uniswapV2Router.swapExactTokensForETH(
            size,
            1,
            path,
            msg.sender,
            deadline
        );
    }

    function sellInSpot() external {
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdc;
        uint256 deadline = block.timestamp + 86400;
        // change amount min
        uniswapV2Router.swapExactETHForTokens(1, path, msg.sender, deadline); // {value: ?}
    }
}
