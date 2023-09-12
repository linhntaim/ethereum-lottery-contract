// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
struct JoiningList {
    /**
     *
     */
    address[] joiners;
    /**
     *
     */
    mapping(address => uint256) times;
    /**
     *
     */
    uint256 sumTimes;
}

/**
 *
 */
library JoiningListMethods {
    /**
     *
     */
    function has(JoiningList storage list, address joiner)
        public
        view
        returns (bool)
    {
        return list.times[joiner] == 0;
    }

    /**
     *
     */
    function insert(JoiningList storage list, address joiner) public {
        if (!has(list, joiner)) {
            list.joiners.push(joiner);
        }
        list.times[joiner] += 1;
        list.sumTimes += 1;
    }
}
