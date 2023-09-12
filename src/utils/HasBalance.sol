// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
abstract contract HasBalance {
    /**
     *
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
