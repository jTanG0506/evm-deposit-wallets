// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    uint8 private constant _decimals = 6;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Allows anyone to mint any amount of tokens to themselves
     * @param amount The amount of tokens to mint
     */
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * @return The number of decimals
     */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }
}
