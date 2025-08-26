// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {CombineCalls} from "../src/CombineCalls.sol";

contract Deploy is Script {
    function deploy() public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        BatchCallAndSponsor implementation = new BatchCallAndSponsor();
        console.log("BatchCallAndSponsor deployed to", address(implementation));

        CombineCalls combineCalls = new CombineCalls(vm.addr(deployerPrivateKey));
        console.log("CombineCalls deployed to", address(combineCalls));

        vm.stopBroadcast();
    }
}
