// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router.sol";
import {IOrderBook} from "../src/interfaces/IOrderBook.sol";
import {ILiquidityPool, Asset, IChainlinkV2V3} from "../src/interfaces/IMux.sol";
import {Adapter} from "../src/adapter.sol";
import {Vault} from "../src/vault.sol";

contract DeployContracts is Script {
    address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);

    address orderBookAddress = 0xa19fD5aB6C8DCffa2A295F78a5Bb4aC543AAF5e3; // proxy
    IOrderBook orderBook = IOrderBook(orderBookAddress);

    address liquidityPoolAddress = 0x3e0199792Ce69DC29A0a36146bFa68bd7C8D6633;
    ILiquidityPool LiquidityPool = ILiquidityPool(liquidityPoolAddress);

    function run() external {
        runAdapter();
        runVault();
    }

    function runAdapter() internal returns (Adapter) {
        vm.startBroadcast();
        Adapter adapter = new Adapter(uniswapRouter, orderBook, LiquidityPool);
        vm.stopBroadcast();
        return (adapter);
    }

    function runVault() internal returns (Vault) {
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        vm.startBroadcast();
        Vault vault = new Vault(usdc);
        vm.stopBroadcast();
        return (vault);
    }
}
