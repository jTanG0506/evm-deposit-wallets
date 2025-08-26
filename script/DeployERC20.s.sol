// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TestERC20} from "../src/TestERC20.sol";

contract DeployTestERC20 is Script {
    TestERC20 public testERC20;

    function deploy(string memory name, string memory symbol) public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);
        testERC20 = new TestERC20(name, symbol);
        vm.stopBroadcast();
    }
}
