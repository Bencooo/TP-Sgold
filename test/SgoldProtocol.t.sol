// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SgoldProtocol.sol";
import "../src/Sgold.sol";
import "../src/GoldPriceFeed.sol";
import {VRFCoordinatorV2_5Mock} from "../../lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {AggregatorV3Interface} from "foundry-chainlink-toolkit/lib/foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

contract SgoldProtocolTest is Test {
    Sgold sgold;
    GoldPriceFeed priceFeed;
    AggregatorV3Interface aggregator;
    VRFCoordinatorV2_5Mock vrfMock;
    SgoldProtocol protocol;

    address treasury = makeAddr("treasury");
    address player = makeAddr("player");

    uint96 constant BASE_FEE = 1e17;
    uint96 constant GAS_PRICE_LINK = 1e9;
    uint64 subscriptionId;

    function setUp() public {
        // 1. Déployer le token
        sgold = new Sgold(address(this));

        // 2. Mock du Chainlink VRF v2.5
        vrfMock = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE_LINK);

        // 3. Créer une subscription Chainlink
        subscriptionId = vrfMock.createSubscription();
        vrfMock.fundSubscription(subscriptionId, 10 ether);

        // 4. Déployer un mock de price feed
        address mockFeed = address(new MockAggregator());
        priceFeed = new GoldPriceFeed(mockFeed);

        // 5. Déployer le protocole
        protocol = new SgoldProtocol(
            address(sgold),
            address(priceFeed),
            treasury,
            subscriptionId
        );

        // 6. Ajouter le protocole comme consumer
        vrfMock.addConsumer(subscriptionId, address(protocol));

        // 7. Définir le minter autorisé
        sgold.setMinter(address(protocol));
    }
}
