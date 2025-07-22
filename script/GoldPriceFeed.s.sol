// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GoldPriceFeed.sol";

contract GoldPriceFeedScript is Script {
    function run() external {
        // Adresse du Chainlink XAU/USD Feed (ex: Ethereum Mainnet)
        address feedAddress = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea;

        vm.startBroadcast();

        GoldPriceFeed goldFeed = new GoldPriceFeed(feedAddress);

        console.log("GoldPriceFeed deployed at:", address(goldFeed));

        int256 goldPrice = goldFeed.getGoldPriceUSD();
        console.log("Current Gold Price (XAU/USD):", goldPrice);

        vm.stopBroadcast();
    }
}
