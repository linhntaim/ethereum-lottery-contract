// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/LuckyGameHub.sol";
import "./utils/random/NumberRangeRoller.sol";
import "./LuckyNumbers.sol";

/**
 *
 */
contract DailySimpleLotteryHub is LuckyGameHub {
    // #region Types

    //

    // #endregion

    // #region Public states

    //

    // #endregion

    // #region Internal states

    //

    // #endregion

    // #region Private states

    /**
     * @dev Date => Game
     */
    mapping(uint256 => address) private _dailyGames;

    // #endregion

    // #region Events

    //

    // #endregion

    // #region Errors

    //

    // #endregion

    // #region Constructor

    constructor()
        LuckyGameHub(
            10**18 / 1000, // Ticket price - 0.001
            10, // Ticket fee rate - 10%
            10**18, // Base reward amount - 1
            20 // Reserve rate
        )
    {}

    // #endregion

    // #region Modifiers

    //

    // #endregion

    // #region Fallback functions

    //

    // #endregion

    // #region External functions

    //

    // #endregion

    // #region Public functions

    /**
     *
     */
    function latest() public view override returns (address) {
        uint256 currentDate = _currentDate();
        require(_dailyGames[currentDate] != address(0), "No game now.");
        return _dailyGames[currentDate];
    }

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _currentDate() internal view returns (uint256) {
        return block.timestamp - (block.timestamp % (24 * 3600));
    }

    /**
     *
     */
    function _create(uint256 accumulatedRewardAmount)
        internal
        override
        returns (address)
    {
        uint256 currentDate = _currentDate(); // UTC

        require(
            _dailyGames[currentDate] == address(0),
            "Game for today has been already created."
        );

        LuckyNumbers game = new LuckyNumbers(
            this,
            currentDate + 1 * 3600, // Started at 01:00:00 UTC
            currentDate + 23 * 3600 - 1, // Ended at 22:59:59 UTC
            accumulatedRewardAmount,
            getTicketPrice(),
            getTicketFeeRate(),
            6, // Ticket num count
            true, // Ticket num repetition enabled
            true, // Ticket num order mattered
            new NumberRangeRoller(0, 9)
        );
        _dailyGames[currentDate] = address(game);

        payable(_dailyGames[currentDate]).transfer(accumulatedRewardAmount);

        return _dailyGames[currentDate];
    }

    /**
     *
     */
    function _retrieveGameContract(address game)
        internal
        pure
        override
        returns (ILuckyGame)
    {
        return LuckyNumbers(game);
    }

    // #endregion

    // #region Private functions

    //

    // #endregion
}
