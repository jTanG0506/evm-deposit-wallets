// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProxyWallet is Ownable {
    error ERC20TransferFailed();
    error NativeTransferFailed();

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    fallback() external payable {}

    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        bool success = IERC20(_token).transfer(owner(), _amount);

        if (!success) {
            revert ERC20TransferFailed();
        }
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");

        if (!success) {
            revert NativeTransferFailed();
        }
    }
}
