// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SgoldProtocol} from "../src/SgoldProtocol.sol";
import {Sgold} from "../src/Sgold.sol";
import {GoldPriceFeed} from "../src/GoldPriceFeed.sol";
import {IVRFSubscriptionV2Plus} from "foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/interfaces/IVRFSubscriptionV2Plus.sol";

contract SgoldProtocolScript is Script {
    function run() external {
        address deployer = msg.sender;

        vm.startBroadcast(deployer);

        // Déployer le token Sgold
        Sgold sgold = new Sgold(deployer);
        console.log("Sgold deployed:", address(sgold));

        // Déployer le Gold Price Feed wrapper (adresse Chainlink XAU/USD Sepolia)
        address goldFeedAddr = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea;
        GoldPriceFeed goldFeed = new GoldPriceFeed(goldFeedAddr);
        console.log("GoldPriceFeed deployed:", address(goldFeed));

        // Créer une nouvelle souscription VRF
        IVRFSubscriptionV2Plus vrfCoordinator = IVRFSubscriptionV2Plus(
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        );

        // uint256 subId = vrfCoordinator.createSubscription();
        uint256 subId =8194662606105862044540898012497416511170457119790745423712660470523520900543;
        console.log("VRF subscription created, ID:", subId);

        // // Fund la subscription avec 0.003 ETH (Sepolia Native)
        // vrfCoordinator.fundSubscriptionWithNative{value: 0.003 ether}(subId);

        // Déployer le protocole
        address treasury = deployer;
        SgoldProtocol protocol = new SgoldProtocol(
            address(sgold),
            address(goldFeed),
            treasury,
            subId
        );
        console.log("SgoldProtocol deployed at:", address(protocol));

        // Ajouter le protocole comme consumer de la subscription
        vrfCoordinator.addConsumer(subId, address(protocol));
        console.log("SgoldProtocol added as VRF consumer");

        // Configurer le minter du token Sgold
        sgold.setMinter(address(protocol));

        // Vérification du prix de l’or pour debug
        int256 goldPrice = goldFeed.getGoldPriceUSD();
        console.log("Current gold price (XAU/USD):", goldPrice);

        // Simuler 10 participations avec très faible montant (ex: 0.001 ETH)
        uint256 participationAmount = 0.000001 ether;

        for (uint256 i = 0; i < 10; i++) {
            protocol.mint{value: participationAmount}();
            console.log("Participation", i + 1, "done");
        }

        // // Tirage
        // protocol.claimReward();
        // console.log("claimReward called");

        vm.stopBroadcast();
    }
}
