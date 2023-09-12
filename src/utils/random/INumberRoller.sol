// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
interface INumberRoller {
    /**
     *
     */
    function valid(uint256 num) external view returns (bool);

    /**
     *
     */
    function roll() external returns (uint256);
}
