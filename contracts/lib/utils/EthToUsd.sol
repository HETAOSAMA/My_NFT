// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library EthToUsd {
    private constant ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function getLatestPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeedInstance = AggregatorV3Interface(ETH_USD_PRICE_FEED);
        (, int price, , , ) = priceFeedInstance.latestRoundData();
        return uint256(price * 1e10);
    }

    function convert(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        return (ethAmount * ethPrice) / 1e18;
    }
}