// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {TestERC20} from "../src/TestERC20.sol";
import {CombineCalls} from "../src/CombineCalls.sol";

contract ERC7702ProxyWalletSweepTest is Test {
    address payable PROXY_WALLET_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant PROXY_WALLET_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address payable PROXY_WALLET_ADDRESS_2 = payable(0xf6B6e939A4cbbda0919b6bAAc4a833eE04eb3AA3);
    uint256 constant PROXY_WALLET_PK_2 = 0x0848285a5bb0628aeeaa7fe66f50b5033f44b0fea84a1306064ebd6771a41a81;

    address payable PROXY_WALLET_ADDRESS_3 = payable(0xBCCc2BBEEDa247cbA485FA1036F0bBee7847Ec6D);
    uint256 constant PROXY_WALLET_PK_3 = 0x2a35d73b627f9b027884433a4a95abbea9eb8976957d674f1b7b9627eb6a952a;

    // Executor's address and private key (Executor will execute transactions on Proxy Wallet's behalf).
    address constant EXECUTOR_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant EXECUTOR_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    address public user = makeAddr("USER");
    address public settlement = makeAddr("SETTLEMENT");

    CombineCalls public combineCalls;
    BatchCallAndSponsor public implementation;
    TestERC20 public usdc;
    TestERC20 public usdt;

    uint256[] public nativeDepositAmounts = [0.01 ether, 0.02 ether, 0.03 ether];

    uint256[] public usdcDepositAmounts = [100_000_000, 200_000_000, 300_000_000];
    uint256[] public usdtDepositAmounts = [50_000_000, 100_000_000, 150_000_000];

    function setUp() public {
        combineCalls = new CombineCalls(EXECUTOR_ADDRESS);
        implementation = new BatchCallAndSponsor();

        usdc = new TestERC20("USDC", "USDC");
        usdt = new TestERC20("USDT", "USDT");

        vm.startPrank(PROXY_WALLET_ADDRESS);
        usdc.mint(usdcDepositAmounts[0]);
        usdt.mint(usdtDepositAmounts[0]);
        vm.deal(PROXY_WALLET_ADDRESS, nativeDepositAmounts[0]);
        vm.stopPrank();

        vm.startPrank(PROXY_WALLET_ADDRESS_2);
        usdc.mint(usdcDepositAmounts[1]);
        usdt.mint(usdtDepositAmounts[1]);
        vm.deal(PROXY_WALLET_ADDRESS_2, nativeDepositAmounts[1]);
        vm.stopPrank();

        vm.startPrank(PROXY_WALLET_ADDRESS_3);
        usdc.mint(usdcDepositAmounts[2]);
        usdt.mint(usdtDepositAmounts[2]);
        vm.deal(PROXY_WALLET_ADDRESS_3, nativeDepositAmounts[2]);
        vm.stopPrank();
    }

    function _getSignature(address payable _proxyWallet, uint256 _privateKey, BatchCallAndSponsor.Call[] memory _calls)
        internal
        view
        returns (bytes memory)
    {
        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < _calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, _calls[i].to, _calls[i].value, _calls[i].data);
        }
        bytes32 digest = keccak256(abi.encodePacked(BatchCallAndSponsor(_proxyWallet).nonce(), encodedCalls));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, MessageHashUtils.toEthSignedMessageHash(digest));
        return abi.encodePacked(r, s, v);
    }

    function test_ERC7702ProxyWalletSweep() public {
        // Read balances from all proxy wallets
        uint256 usdcBalance1 = usdc.balanceOf(PROXY_WALLET_ADDRESS);
        uint256 usdtBalance1 = usdt.balanceOf(PROXY_WALLET_ADDRESS);
        uint256 nativeBalance1 = address(PROXY_WALLET_ADDRESS).balance;

        uint256 usdcBalance2 = usdc.balanceOf(PROXY_WALLET_ADDRESS_2);
        uint256 usdtBalance2 = usdt.balanceOf(PROXY_WALLET_ADDRESS_2);
        uint256 nativeBalance2 = address(PROXY_WALLET_ADDRESS_2).balance;

        uint256 usdcBalance3 = usdc.balanceOf(PROXY_WALLET_ADDRESS_3);
        uint256 usdtBalance3 = usdt.balanceOf(PROXY_WALLET_ADDRESS_3);
        uint256 nativeBalance3 = address(PROXY_WALLET_ADDRESS_3).balance;

        // Prepare calls for each proxy wallet: transfer entire token balance to settlement
        BatchCallAndSponsor.Call[] memory calls1 = new BatchCallAndSponsor.Call[](3);
        calls1[0] = BatchCallAndSponsor.Call({
            to: address(usdc),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, usdcBalance1))
        });
        calls1[1] = BatchCallAndSponsor.Call({
            to: address(usdt),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, usdtBalance1))
        });
        calls1[2] = BatchCallAndSponsor.Call({to: settlement, value: nativeBalance1, data: ""});

        BatchCallAndSponsor.Call[] memory calls2 = new BatchCallAndSponsor.Call[](3);
        calls2[0] = BatchCallAndSponsor.Call({
            to: address(usdc),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, usdcBalance2))
        });
        calls2[1] = BatchCallAndSponsor.Call({
            to: address(usdt),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, usdtBalance2))
        });
        calls2[2] = BatchCallAndSponsor.Call({to: settlement, value: nativeBalance2, data: ""});

        BatchCallAndSponsor.Call[] memory calls3 = new BatchCallAndSponsor.Call[](3);
        calls3[0] = BatchCallAndSponsor.Call({
            to: address(usdc),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, usdcBalance3))
        });
        calls3[1] = BatchCallAndSponsor.Call({
            to: address(usdt),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (settlement, usdtBalance3))
        });
        calls3[2] = BatchCallAndSponsor.Call({to: settlement, value: nativeBalance3, data: ""});

        // 7702 delegations for both proxy wallets to the same implementation
        Vm.SignedDelegation memory signedDelegation1 = vm.signDelegation(address(implementation), PROXY_WALLET_PK);
        Vm.SignedDelegation memory signedDelegation2 = vm.signDelegation(address(implementation), PROXY_WALLET_PK_2);
        Vm.SignedDelegation memory signedDelegation3 = vm.signDelegation(address(implementation), PROXY_WALLET_PK_3);

        vm.startBroadcast(EXECUTOR_PK);
        vm.attachDelegation(signedDelegation1);
        vm.attachDelegation(signedDelegation2);
        vm.attachDelegation(signedDelegation3);

        // Build encodedCalls and signatures for both wallets
        bytes memory sig1 = _getSignature(PROXY_WALLET_ADDRESS, PROXY_WALLET_PK, calls1);
        bytes memory sig2 = _getSignature(PROXY_WALLET_ADDRESS_2, PROXY_WALLET_PK_2, calls2);
        bytes memory sig3 = _getSignature(PROXY_WALLET_ADDRESS_3, PROXY_WALLET_PK_3, calls3);

        // Prepare batched outer call via CombineCalls so both sweeps happen in a single transaction
        address[] memory targets = new address[](3);
        targets[0] = address(PROXY_WALLET_ADDRESS);
        targets[1] = address(PROXY_WALLET_ADDRESS_2);
        targets[2] = address(PROXY_WALLET_ADDRESS_3);

        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("execute((address,uint256,bytes)[],bytes)", calls1, sig1);
        data[1] = abi.encodeWithSignature("execute((address,uint256,bytes)[],bytes)", calls2, sig2);
        data[2] = abi.encodeWithSignature("execute((address,uint256,bytes)[],bytes)", calls3, sig3);

        // Execute both inner calls in a single outer transaction by EXECUTOR
        combineCalls.bulkExecute(targets, values, data);
        vm.stopBroadcast();

        // Verify settlement received both balances
        assertEq(usdc.balanceOf(settlement), usdcBalance1 + usdcBalance2 + usdcBalance3);
        assertEq(usdt.balanceOf(settlement), usdtBalance1 + usdtBalance2 + usdtBalance3);
        assertEq(address(settlement).balance, nativeBalance1 + nativeBalance2 + nativeBalance3);
    }
}
