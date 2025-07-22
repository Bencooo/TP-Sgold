// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VRFConsumerBaseV2Plus} from "foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";
import {Sgold} from "./Sgold.sol";
import {GoldPriceFeed} from "./GoldPriceFeed.sol";

contract SgoldProtocol is VRFConsumerBaseV2Plus {
    // Chainlink VRF
    uint256 public s_subscriptionId;
    address public constant vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 public constant keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint8 public rollingStatus = 0;


    Sgold public immutable sgold;
    GoldPriceFeed public immutable goldFeed;
    address public immutable treasury;


    uint256 public playerCount;
    uint8 public constant threshold = 10;
    address[10] public players;
    address public lastWinner;
    uint256 public totalLottoETH;

    // Events
    event Minted(address indexed user, uint256 eth, uint256 sgoldAmount);
    event RequestSent(uint256 requestId, uint256 playerCount);
    event WinnerSelected(address winner, uint256 reward);

    // Errors
    error ZeroValueNotAllowed();
    error InvalidGoldPrice();
    error TransferToTreasuryFailed();
    error TooManyPlayers();
    error LotteryAlreadyRolling();
    error DrawNotReady();
    error NotWinner(address caller, address winner);
    error RewardTransferFailed();

    constructor(
        address _sgold,
        address _goldFeed,
        address _treasury,
        uint256 _subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        sgold = Sgold(_sgold);
        goldFeed = GoldPriceFeed(_goldFeed);
        treasury = _treasury;
        s_subscriptionId = _subscriptionId;
    }

    function mint() public payable {
        if (msg.value == 0) revert ZeroValueNotAllowed();

        int256 goldPrice = goldFeed.getGoldPriceUSD();
        if (goldPrice <= 0) revert InvalidGoldPrice();

        uint256 valueUsd = (msg.value * uint256(goldPrice)) / 1e8;

        // 70% en token
        uint256 tokenAmount = (valueUsd * 70) / 100;
        sgold.mint(msg.sender, tokenAmount * 1e18);

        // 10% trésorerie
        uint256 treasuryAmount = (msg.value * 10) / 100;
        (bool sentTreasury, ) = treasury.call{value: treasuryAmount}("");
        if (!sentTreasury) revert TransferToTreasuryFailed();

        // 20% loterie
        uint256 lottoAmount = msg.value - treasuryAmount - ((msg.value * 70) / 100);
        totalLottoETH += lottoAmount;

        if (playerCount >= threshold) revert TooManyPlayers();
        players[playerCount] = msg.sender;
        playerCount++;

        emit Minted(msg.sender, msg.value, tokenAmount);

        if (playerCount == threshold && rollingStatus == 0) {
            rollLotto();
        }
    }

    function rollLotto() internal {
        if (rollingStatus != 0) revert LotteryAlreadyRolling();

        rollingStatus = 1;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: 1,
                callbackGasLimit: 150_000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );
        emit RequestSent(requestId, playerCount);
    }

    function fulfillRandomWords(
        uint256, 
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % playerCount;
        lastWinner = players[winnerIndex];
        rollingStatus = 2;
    }

    function claimReward() external {
        if (rollingStatus != 2) revert DrawNotReady();
        if (msg.sender != lastWinner) revert NotWinner(msg.sender, lastWinner);

        uint256 reward = totalLottoETH;
        totalLottoETH = 0;
        rollingStatus = 0;

        for (uint256 i = 0; i < threshold; i++) {
            delete players[i];
        }
        playerCount = 0;

        (bool sent, ) = msg.sender.call{value: reward}("");
        if (!sent) revert RewardTransferFailed();

        emit WinnerSelected(msg.sender, reward);
    }

    receive() external payable {}
}
