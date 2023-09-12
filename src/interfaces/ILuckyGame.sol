// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
interface ILuckyGame {
    /**
     *
     */
    function getWinners() external view returns (address[] memory);

    /**
     *
     */
    function getWinningAmount(address winner) external view returns (uint256);

    /**
     *
     */
    function join() external payable;

    /**
     *
     */
    function join(address joiner) external payable;

    /**
     *
     */
    function join(string memory ticket) external payable;

    /**
     *
     */
    function join(address joiner, string memory ticket) external payable;

    /**
     *
     */
    function draw() external;

    /**
     *
     */
    function recordWinners() external;

    /**
     *
     */
    function rewardWinners() external;

    /**
     *
     */
    function withdraw() external;
}
