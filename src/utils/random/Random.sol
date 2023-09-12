// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
library Random {
    /**
     *
     */
    function generate(uint256 min, uint256 max) public view returns (uint256) {
        return generate(min, max, 0);
    }

    /**
     *
     */
    function generate(
        uint256 min,
        uint256 max,
        uint256 seed
    ) public view returns (uint256) {
        if (min == max) {
            return min;
        }
        if (min > max) {
            uint256 t = min;
            min = max;
            max = t;
        }
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    block.coinbase,
                    msg.sender,
                    seed
                )
            )
        );
        return (random % (max - min + 1)) + min;
    }
}

/**
 *
 */
struct RandomGenerator {
    /**
     *
     */
    uint256 autoSeed;
}

library RandomGeneratorMethods {
    /**
     *
     */
    function plantSeed(RandomGenerator storage generator) public {
        generator.autoSeed = Random.generate(0, block.number);
    }

    /**
     *
     */
    function generate(
        RandomGenerator storage generator,
        uint256 min,
        uint256 max
    ) public returns (uint256) {
        generator.autoSeed += 1;
        return Random.generate(min, max, generator.autoSeed);
    }
}
