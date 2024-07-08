// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router.sol";
import {IOrderBook} from "./interfaces/IOrderBook.sol";

contract Adapter {
    IUniswapV2Router02 public uniswapV2Router; // Uniswap
    IOrderBook public orderBook; // MUX

    constructor(IUniswapV2Router02 _uniswapV2Router, IOrderBook _orderBook) {
        uniswapV2Router = _uniswapV2Router;
        orderBook = _orderBook;
    }

    function openShortPosition(
        bytes32 subAccountId,
        uint96 collateralAmount,
        uint96 size,
        uint96 price,
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline,
        bytes32 referralCode,
        PositionOrderExtra memory extra
    ) external {
        orderBook.placePositionOrder3(
            subAccountId,
            collateralAmount,
            size,
            price,
            profitTokenId,
            flags,
            deadline,
            referralCode,
            extra
        );
    }

    function closeShortPosition(
        bytes32 subAccountId,
        uint96 collateralAmount,
        uint96 size,
        uint96 price,
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline,
        bytes32 referralCode,
        PositionOrderExtra memory extra
    ) external {
        orderBook.placePositionOrder3(
            subAccountId,
            collateralAmount,
            size,
            price,
            profitTokenId,
            flags,
            deadline,
            referralCode,
            extra
        );
    }

    function buyInSpot(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        uniswapV2Router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function sellInSpot(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        uniswapV2Router.swapExactETHForTokens(amountOutMin, path, to, deadline);
    }
}
