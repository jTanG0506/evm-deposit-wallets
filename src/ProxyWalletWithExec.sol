// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProxyWalletWithExec is Ownable {
    error ERC20TransferFailed();
    error NativeTransferFailed();
    error CallFailed(uint256 index, bytes returnData);
    error SingleCallFailed(bytes returnData);

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

    /// @notice Execute multiple arbitrary calls from the wallet
    /// @dev Only callable by the owner; reverts if any individual call fails
    /// @param targets The addresses to call
    /// @param values The ETH values to send with each call
    /// @param data The calldata for each call
    /// @return returnData The return data for each successful call
    function bulkExecute(address[] calldata targets, uint256[] calldata values, bytes[] calldata data)
        external
        onlyOwner
        returns (bytes[] memory returnData)
    {
        uint256 length = targets.length;
        returnData = new bytes[](length);

        for (uint256 i = 0; i < length;) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata callData = data[i];

            (bool success, bytes memory ret) = target.call{value: value}(callData);
            if (!success) {
                revert CallFailed(i, ret);
            }
            returnData[i] = ret;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Execute a single arbitrary call (cheaper than bulk when only one call is needed)
    /// @dev Only callable by the owner; reverts and returns revert data on failure
    /// @param target The address to call
    /// @param value The ETH value to send with the call
    /// @param data The calldata for the call
    /// @return returnData The return data from the call
    function execute(address target, uint256 value, bytes calldata data)
        external
        onlyOwner
        returns (bytes memory returnData)
    {
        (bool success, bytes memory ret) = target.call{value: value}(data);
        if (!success) {
            revert SingleCallFailed(ret);
        }

        return ret;
    }
}
