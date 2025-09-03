// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {CombineCalls} from "../src/CombineCalls.sol";

contract Deploy is Script {
    bytes32 constant BATCH_CALL_SALT = keccak256("BatchCallAndSponsor_v1");
    bytes32 constant COMBINE_CALLS_SALT = keccak256("CombineCalls_v1");

    function deploy() public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy BatchCallAndSponsor using CREATE2
        BatchCallAndSponsor implementation = new BatchCallAndSponsor{salt: BATCH_CALL_SALT}();
        console.log("BatchCallAndSponsor deployed to", address(implementation));

        // Deploy CombineCalls using CREATE2
        CombineCalls combineCalls = new CombineCalls{salt: COMBINE_CALLS_SALT}(deployer);
        console.log("CombineCalls deployed to", address(combineCalls));

        vm.stopBroadcast();
    }

    function predictAddresses() public view returns (address batchCallAddr, address combineCallsAddr) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);

        // Predict BatchCallAndSponsor address
        bytes memory batchCallBytecode = abi.encodePacked(type(BatchCallAndSponsor).creationCode);
        batchCallAddr = vm.computeCreate2Address(BATCH_CALL_SALT, keccak256(batchCallBytecode), deployer);

        // Predict CombineCalls address
        bytes memory combineCallsBytecode = abi.encodePacked(type(CombineCalls).creationCode, abi.encode(deployer));
        combineCallsAddr = vm.computeCreate2Address(COMBINE_CALLS_SALT, keccak256(combineCallsBytecode), deployer);
    }
}
