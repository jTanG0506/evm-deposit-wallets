// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TestERC20} from "../src/TestERC20.sol";

contract MintTestERC20 is Script {
    function mint() public {
        string[] memory tokens = vm.envString("ERC20_TOKENS", ",");
        uint256[] memory amounts = vm.envUint("ERC20_AMOUNTS", ",");

        uint256[] memory privateKeys = _loadPrivateKeys();

        uint256 tokenLength = tokens.length;
        uint256 privateKeyLength = privateKeys.length;

        for (uint256 i = 0; i < tokenLength; i++) {
            for (uint256 j = 0; j < privateKeyLength; j++) {
                vm.startBroadcast(privateKeys[j]);
                TestERC20(payable(vm.parseAddress(tokens[i]))).mint(amounts[j]);

                address proxyWallet = vm.addr(privateKeys[j]);
                console.log(
                    string.concat(
                        "Minted ", vm.toString(amounts[j]), " of ", tokens[i], " to ", vm.toString(proxyWallet)
                    )
                );
                vm.stopBroadcast();
            }
        }
    }

    function _loadPrivateKeys() internal view returns (uint256[] memory keys) {
        bytes32[] memory arr = vm.envBytes32("PRIVATE_KEYS", ",");
        keys = new uint256[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            keys[i] = uint256(arr[i]);
        }
    }
}
