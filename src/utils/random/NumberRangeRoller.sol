// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NumberRoller.sol";

/**
 *
 */
contract NumberRangeRoller is NumberRoller {
    /**
     *
     */
    uint256 private _start;

    /**
     *
     */
    uint256 private _end;

    /**
     *
     */
    constructor(uint256 start, uint256 end) NumberRoller() {
        _start = start;
        _end = end;
    }

    /**
     *
     */
    function valid(uint256 num) external view returns (bool) {
        return num >= _start && num <= _end;
    }

    /**
     *
     */
    function roll() external returns (uint256) {
        return _roll(_start, _end);
    }
}
