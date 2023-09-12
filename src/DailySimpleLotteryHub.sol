// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/LuckyGameHub.sol";
import "./utils/random/NumberRangeRoller.sol";
import "./LuckyNumbers.sol";

/**
 *
 */
contract DailySimpleLotteryHub is LuckyGameHub {
    /**
     *
     */
    uint256 private _ticketPrice = 10**18 / 100; // 0.01 coin

    /**
     *
     */
    uint256 private _baseRewardingAmount = 10**18; // 1 coin

    /**
     * @dev Extra reward based on game performance (income). Percentage value, range = [0, 100].
     */
    uint256 private _bonusRewardingRate = 90; // 90%

    /**
     * Start at => Game
     */
    mapping(uint256 => address) private _dailyGames;

    /**
     *
     */
    function latest() public view override returns (address) {
        uint256 currentDate = _currentDate();
        require(_dailyGames[currentDate] != address(0), "No game now.");
        return _dailyGames[currentDate];
    }

    /**
     *
     */
    function _create() internal override returns (address) {
        uint256 currentDate = _currentDate(); // UTC

        require(
            _dailyGames[currentDate] == address(0),
            "Game for today has been already created."
        );
        require(getBalance() >= _baseRewardingAmount, "Fund is not enough.");

        LuckyNumbers game = new LuckyNumbers(
            this,
            _ticketPrice,
            currentDate + 1 * 3600, // Started at 01:00 UTC
            currentDate + 23 * 3600, // Ended at 23:00 UTC
            _baseRewardingAmount,
            _bonusRewardingRate,
            6,
            new NumberRangeRoller(0, 9),
            true,
            true
        );
        _dailyGames[currentDate] = address(game);

        payable(_dailyGames[currentDate]).transfer(_baseRewardingAmount);

        return _dailyGames[currentDate];
    }

    /**
     *
     */
    function _currentDate() internal view returns (uint256) {
        return block.timestamp - (block.timestamp % (24 * 3600));
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
}
