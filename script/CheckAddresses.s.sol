// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Deploy} from "./Deploy.s.sol";

contract CheckAddresses is Script {
    function check(string[] memory rpcUrls) public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);

        // Predict addresses using the same logic as Deploy.predictAddresses()
        Deploy deployScript = new Deploy();
        (address batchCallAddr, address combineCallsAddr) = deployScript.predictAddresses();

        console.log("Checking addresses:");
        console.log("  Deployer:", deployer);
        console.log("  BatchCallAndSponsor:", batchCallAddr);
        console.log("  CombineCalls:", combineCallsAddr);
        console.log("");

        bool hasConflicts = false;

        for (uint256 i = 0; i < rpcUrls.length; i++) {
            string memory rpcUrl = rpcUrls[i];
            console.log("Checking RPC:", rpcUrl);

            vm.createSelectFork(rpcUrl);

            // Check if contracts already exist
            uint256 batchCallSize = batchCallAddr.code.length;
            uint256 combineCallsSize = combineCallsAddr.code.length;

            if (batchCallSize > 0) {
                console.log("  [CONFLICT] BatchCallAndSponsor already exists (code size:", batchCallSize, "bytes)");
                hasConflicts = true;
            } else {
                console.log("  [OK] BatchCallAndSponsor address is available");
            }

            if (combineCallsSize > 0) {
                console.log("  [CONFLICT] CombineCalls already exists (code size:", combineCallsSize, "bytes)");
                hasConflicts = true;
            } else {
                console.log("  [OK] CombineCalls address is available");
            }

            console.log("");
        }

        if (hasConflicts) {
            console.log("RESULT: Conflicts detected! Consider using a different salt.");
            revert("Address conflicts detected");
        } else {
            console.log("RESULT: No conflicts detected. Safe to deploy.");
        }
    }
}
