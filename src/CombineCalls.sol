// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CombineCalls is Ownable {
    error CallFailed(uint256 index, bytes returnData);

    constructor(address _owner) Ownable(_owner) {}

    receive() external payable {}

    fallback() external payable {}

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
}
