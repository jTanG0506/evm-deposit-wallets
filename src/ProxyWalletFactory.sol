// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./ProxyWallet.sol";

contract ProxyWalletFactory is Ownable {
    event WalletDeployed(address wallet, bytes32 salt);

    constructor(address _owner) Ownable(_owner) {}

    /// @notice Deploys a wallet using precomputed bytecode hash
    function deploy(bytes32 _salt) external returns (address wallet) {
        bytes memory bytecode = abi.encodePacked(type(ProxyWallet).creationCode, abi.encode(msg.sender));

        wallet = Create2.deploy(0, _salt, bytecode);
        emit WalletDeployed(wallet, _salt);
    }

    /// @notice Computes CREATE2 address for a DepositWallet
    function computeAddress(bytes32 _salt, address _owner) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(type(ProxyWallet).creationCode, abi.encode(_owner));

        bytes32 bytecodeHash = keccak256(bytecode);
        return Create2.computeAddress(_salt, bytecodeHash);
    }
}
