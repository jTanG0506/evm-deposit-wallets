// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {TestERC20} from "../src/TestERC20.sol";

contract ERC7702ProxyWalletTest is Test {
    // Proxy wallet's address and private key (EOA with no initial contract code).
    address payable PROXY_WALLET_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant PROXY_WALLET_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // Executor's address and private key (Executor will execute transactions on Proxy Wallet's behalf).
    address constant EXECUTOR_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant EXECUTOR_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    address public user = makeAddr("USER");
    address public settlement = makeAddr("SETTLEMENT");

    BatchCallAndSponsor public implementation;
    TestERC20 public token;

    uint256 public tokenDepositAmount = 500 * 10 ** 6;
    uint256 public nativeDepositAmount = 1 ether;

    event CallExecuted(address indexed to, uint256 value, bytes data);
    event BatchExecuted(uint256 indexed nonce, BatchCallAndSponsor.Call[] calls);

    function setUp() public {
        implementation = new BatchCallAndSponsor();
        token = new TestERC20("TestERC20", "TEST");

        vm.startPrank(user);
        token.mint(10000 * 10 ** token.decimals());
        token.transfer(PROXY_WALLET_ADDRESS, tokenDepositAmount);
        vm.deal(PROXY_WALLET_ADDRESS, nativeDepositAmount);
        vm.stopPrank();
    }

    function test_SponsoredERCDeposit() public {
        uint256 proxyWalletTokenBalance = token.balanceOf(PROXY_WALLET_ADDRESS);

        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);

        calls[0] = BatchCallAndSponsor.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, proxyWalletTokenBalance))
        });

        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), PROXY_WALLET_PK);

        vm.startBroadcast(EXECUTOR_PK);
        vm.attachDelegation(signedDelegation);

        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        bytes32 digest = keccak256(abi.encodePacked(BatchCallAndSponsor(PROXY_WALLET_ADDRESS).nonce(), encodedCalls));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PROXY_WALLET_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        BatchCallAndSponsor(PROXY_WALLET_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();

        assertEq(token.balanceOf(settlement), proxyWalletTokenBalance);
    }

    function test_SponsoredNativeDeposit() public {
        uint256 proxyWalletNativeBalance = address(PROXY_WALLET_ADDRESS).balance;

        console.log("Proxy wallet native balance:", proxyWalletNativeBalance);

        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);

        calls[0] = BatchCallAndSponsor.Call({to: address(settlement), value: nativeDepositAmount, data: ""});

        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), PROXY_WALLET_PK);

        vm.startBroadcast(EXECUTOR_PK);
        vm.attachDelegation(signedDelegation);

        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        bytes32 digest = keccak256(abi.encodePacked(BatchCallAndSponsor(PROXY_WALLET_ADDRESS).nonce(), encodedCalls));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PROXY_WALLET_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        BatchCallAndSponsor(PROXY_WALLET_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();
    }
}
