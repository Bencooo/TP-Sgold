// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Sgold.sol";

contract SgoldScript is Script {
    function run() external {
        address owner = msg.sender;

        vm.startBroadcast();

        Sgold sgold = new Sgold(owner);
        console.log("Sgold token deployed at:", address(sgold));
        console.log("Owner is:", owner);

        vm.stopBroadcast();
    }
}
