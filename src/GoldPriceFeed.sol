// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "../lib/foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

error InvalidFeedAddress();

contract GoldPriceFeed {
    AggregatorV3Interface internal immutable priceFeed;

    constructor(address _feedAddress) {
        if (_feedAddress == address(0)) {
            revert InvalidFeedAddress();
        }
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    /// @notice Renvoie le prix de l'or en USD avec 8 décimales (ex: 195000000 = $1950.00)
    function getGoldPriceUSD() public view returns (int256) {
        (
            , // roundID
            int256 price,
            , // startedAt
            , // updatedAt
            // answeredInRound
        ) = priceFeed.latestRoundData();

        return price;
    }

    /// @notice Renvoie le nombre de décimales utilisées par le feed
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    /// @notice Renvoie l'adresse du Chainlink aggregator
    function getFeedAddress() public view returns (address) {
        return address(priceFeed);
    }
}
