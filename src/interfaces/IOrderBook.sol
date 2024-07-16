// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

interface IOrderBook {
    struct PositionOrderExtra {
        // tp/sl strategy
        uint96 tpPrice; // take-profit price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
        uint96 slPrice; // stop-loss price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
        uint8 tpslProfitTokenId; // only valid when flags.POSITION_TPSL_STRATEGY.
        uint32 tpslDeadline; // only valid when flags.POSITION_TPSL_STRATEGY.
    }

    struct PositionOrder {
        uint64 id;
        bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
        uint96 collateral; // erc20.decimals
        uint96 size; // 1e18
        uint96 price; // 1e18
        uint8 profitTokenId;
        uint8 flags;
        uint32 placeOrderTime; // 1e0
        uint24 expire10s; // 10 seconds. deadline = placeOrderTime + expire * 10
    }

    struct SubAccount {
        // slot
        uint96 collateral;
        uint96 size;
        uint32 lastIncreasedTime;
        // slot
        uint96 entryPrice;
        uint128 entryFunding; // entry longCumulativeFundingRate for long position. entry shortCumulativeFunding for short position
    }

    function placePositionOrder3(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode,
        PositionOrderExtra memory extra
    ) external payable;

    function fillPositionOrder(
        uint64 orderId,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external;

    function depositCollateral(
        bytes32 subAccountId,
        uint256 collateralAmount
    ) external payable;
}
