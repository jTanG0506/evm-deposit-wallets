// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";

import {ProxyWalletWithExec} from "../src/ProxyWalletWithExec.sol";
import {ProxyWalletWithExecFactory} from "../src/ProxyWalletWithExecFactory.sol";
import {TestERC20} from "../src/TestERC20.sol";

contract ProxyWalletWithExecFactoryTest is Test {
    ProxyWalletWithExecFactory public proxyWalletFactory;
    address public deployer = makeAddr("DEPLOYER");
    address public user = makeAddr("USER");
    address public settlement = makeAddr("SETTLEMENT");
    TestERC20 public token;

    address public proxyWalletAddress;
    ProxyWalletWithExec public proxyWallet;

    function setUp() public {
        token = new TestERC20("TestERC20", "TEST");

        vm.startPrank(user);
        token.mint(10000 * 10 ** token.decimals());
        vm.stopPrank();

        vm.startPrank(deployer);
        proxyWalletFactory = new ProxyWalletWithExecFactory(deployer);
        proxyWalletAddress = proxyWalletFactory.deploy(keccak256("user"));
        vm.stopPrank();

        proxyWallet = ProxyWalletWithExec(payable(proxyWalletAddress));
    }

    function test_Deploy() public {
        vm.startPrank(deployer);
        proxyWalletFactory = new ProxyWalletWithExecFactory(deployer);
        proxyWalletFactory.deploy(keccak256("user"));
        vm.stopPrank();
    }

    function test_DepositERC20() public {
        uint256 depositAmount = 500 * 10 ** token.decimals();

        uint256 proxyWalletStartingBalance = token.balanceOf(proxyWalletAddress);

        vm.prank(user);
        token.transfer(proxyWalletAddress, depositAmount);

        assertEq(token.balanceOf(proxyWalletAddress), proxyWalletStartingBalance + depositAmount);

        vm.prank(deployer);
        proxyWallet.withdrawERC20(address(token), settlement, depositAmount);

        assertEq(token.balanceOf(settlement), depositAmount);
    }

    function test_DepositNative() public {
        uint256 depositAmount = 0.05 ether;

        uint256 proxyWalletStartingBalance = address(proxyWalletAddress).balance;
        vm.deal(user, 1 ether);

        vm.prank(user);
        proxyWalletAddress.call{value: depositAmount}("");

        assertEq(address(proxyWalletAddress).balance, proxyWalletStartingBalance + depositAmount);

        vm.prank(deployer);
        proxyWallet.withdrawETH(settlement, depositAmount);

        assertEq(address(settlement).balance, depositAmount);
    }

    function test_Execute() public {
        uint256 amount = 1000 * 10 ** token.decimals();

        vm.prank(user);
        token.transfer(proxyWalletAddress, amount);

        vm.prank(deployer);
        proxyWallet.execute(address(token), 0, abi.encodeCall(IERC20.transfer, (settlement, amount)));

        assertEq(token.balanceOf(settlement), amount);
    }

    function test_BulkExecute() public {
        uint256 amountPerCall = 1000 * 10 ** token.decimals();
        uint256 total = amountPerCall * 2;

        vm.prank(user);
        token.transfer(proxyWalletAddress, total);

        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory data = new bytes[](2);

        targets[0] = address(token);
        values[0] = 0;
        data[0] = abi.encodeCall(IERC20.transfer, (settlement, amountPerCall));

        targets[1] = address(token);
        values[1] = 0;
        data[1] = abi.encodeCall(IERC20.transfer, (settlement, amountPerCall));

        vm.prank(deployer);
        proxyWallet.bulkExecute(targets, values, data);

        assertEq(token.balanceOf(settlement), total);
    }
}
