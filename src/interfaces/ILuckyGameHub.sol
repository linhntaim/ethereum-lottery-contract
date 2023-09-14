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
    function getTicketPrice() external view returns (uint256);

    /**
     *
     */
    function getTicketFeeRate() external view returns (uint256);

    /**
     *
     */
    function getBaseRewardAmount() external view returns (uint256);

    /**
     *
     */
    function getReserveRate() external view returns (uint256);

    /**
     *
     */
    function create() external returns (address);

    /**
     *
     */
    function withdraw() external;

    /**
     *
     */
    function latest() external view returns (address);

    /**
     *
     */
    function owned(address game) external view returns (bool);
}
