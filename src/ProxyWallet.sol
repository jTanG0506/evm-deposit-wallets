// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProxyWallet is Ownable {
    error ERC20TransferFailed();
    error NativeTransferFailed();

    constructor(address _owner) Ownable(_owner) {}

    receive() external payable {}

    fallback() external payable {}

    function withdrawERC20(address _token, address _to, uint256 _amount) external onlyOwner {
        bool success = IERC20(_token).transfer(_to, _amount);

        if (!success) {
            revert ERC20TransferFailed();
        }
    }

    function withdrawETH(address _to, uint256 _amount) external onlyOwner {
        (bool success,) = _to.call{value: _amount}("");

        if (!success) {
            revert NativeTransferFailed();
        }
    }
}
