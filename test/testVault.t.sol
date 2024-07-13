// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {Vault} from "../src/vault.sol";
import {Adapter} from "../src/adapter.sol";
import {DeployContracts} from "../script/DeployContracts.s.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router.sol";
import {IOrderBook} from "../src/interfaces/IOrderBook.sol";
import {ILiquidityPool, Asset, IChainlinkV2V3} from "../src/interfaces/IMux.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract TestVault is Test, Script {
    Vault vault;
    Adapter adapter;

    string public RPC_URL =
        "https://arb-mainnet.g.alchemy.com/v2/bpSGALeEKAzvQcP1DFf7w6jk_f8WhU9d";

    address uniswapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);

    address orderBookAddress = 0xa19fD5aB6C8DCffa2A295F78a5Bb4aC543AAF5e3; // proxy
    IOrderBook orderBook = IOrderBook(orderBookAddress);

    address liquidityPoolAddress = 0x3e0199792Ce69DC29A0a36146bFa68bd7C8D6633;
    ILiquidityPool LiquidityPool = ILiquidityPool(liquidityPoolAddress);

    address public user;
    address public broker;
    IERC20 public usdcToken;
    uint96 START_BAL = 1609320000;

    function run() public {
        runAdapter();
        runVault();
    }

    function runAdapter() internal returns (Adapter) {
        vm.startBroadcast();
        adapter = new Adapter(uniswapRouter, orderBook, LiquidityPool);

        vm.stopBroadcast();
        return (adapter);
    }

    function runVault() internal returns (Vault) {
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        vm.startBroadcast();
        vault = new Vault(usdc);
        vault.setAdapter(payable(adapter));
        vm.stopBroadcast();
        return (vault);
    }

    function setUp() external {
        uint256 blockNumber = 231350650;
        uint256 forkID = vm.createFork(RPC_URL, blockNumber);

        vm.selectFork(forkID);

        user = makeAddr("user");
        broker = 0x988aA44E12c7BCE07E449A4156b4A269d6642B3A;
        usdcToken = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        deal(address(usdcToken), user, START_BAL);
    }

    function testDeposit() public {
        run();
        vm.startPrank(user);
        vm.roll(block.number + 10);

        usdcToken.approve(address(vault), START_BAL);
        vault.deposit(START_BAL);
        vm.stopPrank();
        assertEq(vault.totalSupply(), START_BAL);
        assertEq(vault.balanceOf(user), START_BAL);
    }

    function fillOrder() internal {
        uint96 assetPrice = uint96(adapter.getAssetPrice(3));
        orderBook.fillPositionOrder(
            orderId,
            1000000000000000000,
            assetPrice,
            0
        );
    }

    function testFillOrder() public {
        vm.prank(broker);
        fillOrder();
    }
}
