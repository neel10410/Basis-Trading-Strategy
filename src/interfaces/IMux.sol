// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Asset {
    // slot
    // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
    // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
    // different chains are the same.
    // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
    // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
    bytes32 symbol;
    // slot
    address tokenAddress; // erc20.address
    uint8 id;
    uint8 decimals; // erc20.decimals
    uint56 flags; // a bitset of ASSET_*
    uint24 _flagsPadding;
    // slot
    uint32 initialMarginRate; // 1e5
    uint32 maintenanceMarginRate; // 1e5
    uint32 minProfitRate; // 1e5
    uint32 minProfitTime; // 1e0
    uint32 positionFeeRate; // 1e5
    // note: 96 bits remaining
    // slot
    address referenceOracle;
    uint32 referenceDeviation; // 1e5
    uint8 referenceOracleType;
    uint32 halfSpread; // 1e5
    // note: 24 bits remaining
    // slot
    uint96 credit;
    uint128 _reserved2;
    // slot
    uint96 collectedFee;
    uint32 liquidationFeeRate; // 1e5
    uint96 spotLiquidity;
    // note: 32 bits remaining
    // slot
    uint96 maxLongPositionSize;
    uint96 totalLongPosition;
    // note: 64 bits remaining
    // slot
    uint96 averageLongPrice;
    uint96 maxShortPositionSize;
    // note: 64 bits remaining
    // slot
    uint96 totalShortPosition;
    uint96 averageShortPrice;
    // note: 64 bits remaining
    // slot, less used
    address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
    uint32 spotWeight; // 1e0
    uint32 longFundingBaseRate8H; // 1e5
    uint32 longFundingLimitRate8H; // 1e5
    // slot
    uint128 longCumulativeFundingRate; // Σ_t fundingRate_t. in tokens. 1e18
    uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t. in usd. 1e18
}

interface ILiquidityPool {
    function getSubAccount(
        bytes32 subAccountId
    )
        external
        view
        returns (
            uint96 collateral,
            uint96 size,
            uint32 lastIncreasedTime,
            uint96 entryPrice,
            uint128 entryFunding
        );
    function getAssetAddress(uint8 assetId) external view returns (address);

    function getAssetInfo(uint8 assetId) external view returns (Asset memory);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

interface IChainlinkV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IChainlinkV2V3 is IChainlink, IChainlinkV3 {}
