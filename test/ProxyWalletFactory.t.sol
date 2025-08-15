// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ProxyWallet} from "../src/ProxyWallet.sol";
import {ProxyWalletFactory} from "../src/ProxyWalletFactory.sol";
import {TestERC20} from "../src/TestERC20.sol";

contract ProxyWalletFactoryTest is Test {
    ProxyWalletFactory public proxyWalletFactory;
    address public deployer = makeAddr("DEPLOYER");
    address public user = makeAddr("USER");
    address public settlement = makeAddr("SETTLEMENT");
    TestERC20 public token;

    address public proxyWalletAddress;
    ProxyWallet public proxyWallet;

    function setUp() public {
        token = new TestERC20("TestERC20", "TEST");

        vm.startPrank(user);
        token.mint(10000 * 10 ** token.decimals());
        vm.stopPrank();

        vm.startPrank(deployer);
        proxyWalletFactory = new ProxyWalletFactory(deployer);
        proxyWalletAddress = proxyWalletFactory.deploy(keccak256("user"));
        vm.stopPrank();

        proxyWallet = ProxyWallet(payable(proxyWalletAddress));
    }

    function test_Deploy() public {
        vm.startPrank(deployer);
        proxyWalletFactory = new ProxyWalletFactory(deployer);
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
}
