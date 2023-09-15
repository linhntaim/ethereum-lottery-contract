// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
interface ILuckyGame {
    /**
     *
     */
    function getStartAt() external view returns (uint256);

    /**
     *
     */
    function getEndAt() external view returns (uint256);

    /**
     *
     */
    function getBaseRewardAmount() external view returns (uint256);

    /**
     *
     */
    function getTicketPrice() external view returns (uint256);

    /**
     *
     */
    function getTicketFeeRate() external view returns (uint256);

    /**
     *
     */
    function countJoiners() external view returns (uint256);

    /**
     *
     */
    function isJoiner(address someone) external view returns (bool);

    /**
     *
     */
    function countTickets() external view returns (uint256);

    /**
     *
     */
    function getIncome() external view returns (uint256);

    /**
     *
     */
    function getFees() external view returns (uint256);

    /**
     *
     */
    function getPerformanceRewardAmount() external view returns (uint256);

    /**
     *
     */
    function getRewardAmount() external view returns (uint256);

    /**
     *
     */
    function countWinners() external view returns (uint256);

    /**
     *
     */
    function isWinner(address someone) external view returns (bool);

    /**
     *
     */
    function paused() external view returns (bool);

    /**
     *
     */
    function pause() external;

    /**
     *
     */
    function resume() external;

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
