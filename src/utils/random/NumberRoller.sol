// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Random.sol";
import "./INumberRoller.sol";

/**
 *
 */
abstract contract NumberRoller is INumberRoller {
    using RandomGeneratorMethods for RandomGenerator;

    /**
     *
     */
    RandomGenerator private _randomizer;

    /**
     *
     */
    constructor() {
        _randomizer.plantSeed();
    }

    /**
     *
     */
    function _roll(uint256 min, uint256 max) internal returns (uint256) {
        return _randomizer.generate(min, max);
    }
}
