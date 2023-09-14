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
    uint256 private _numStart;

    /**
     *
     */
    uint256 private _numEnd;

    /**
     *
     */
    constructor(uint256 numStart, uint256 numEnd) NumberRoller() {
        _numStart = numStart;
        _numEnd = numEnd;
    }

    /**
     *
     */
    function getNumStart() external view returns (uint256) {
        return _numStart;
    }

    /**
     *
     */
    function getNumEnd() external view returns (uint256) {
        return _numEnd;
    }

    /**
     *
     */
    function valid(uint256 num) external view returns (bool) {
        return num >= _numStart && num <= _numEnd;
    }

    /**
     *
     */
    function roll() external returns (uint256) {
        return _roll(_numStart, _numEnd);
    }
}
