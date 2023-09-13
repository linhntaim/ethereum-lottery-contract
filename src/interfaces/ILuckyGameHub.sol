// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILuckyGame.sol";

/**
 *
 */
interface ILuckyGameHub {
    /**
     *
     */
    function latest() external view returns (address);

    /**
     *
     */
    function latestContract() external view returns (ILuckyGame);

    /**
     *
     */
    function owned(address game) external view returns (bool);

    /**
     *
     */
    function create() external returns (address);

    /**
     *
     */
    function withdraw() external;
}
