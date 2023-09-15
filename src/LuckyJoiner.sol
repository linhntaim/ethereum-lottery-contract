// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./abstracts/LuckyGame.sol";
import "./interfaces/ILuckyGameHub.sol";
import "./utils/random/NumberRangeRoller.sol";

/**
 *
 */
contract LuckyJoiner is LuckyGame {
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

    uint256 private _drawnPosition;

    // #endregion

    // #region Events

    //

    // #endregion

    // #region Errors

    //

    // #endregion

    // #region Constructor

    /**
     *
     */
    constructor(
        ILuckyGameHub hubContract,
        uint256 startAt,
        uint256 endAt,
        uint256 baseRewardAmount,
        uint256 ticketPrice,
        uint256 ticketFeeRate
    )
        LuckyGame(
            hubContract,
            startAt,
            endAt,
            baseRewardAmount,
            ticketPrice,
            ticketFeeRate,
            true // One-time limited?
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

    //

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _randomizeTicket() internal pure override returns (string memory) {
        return "";
    }

    /**
     *
     */
    function _joining(address joiner, string memory ticket) internal override {
        // Do nothing
    }

    /**
     *
     */
    function _draw() internal virtual override {
        NumberRangeRoller numberRoller = new NumberRangeRoller(
            1,
            countJoiners()
        );
        _drawnPosition = numberRoller.roll();
    }

    /**
     *
     */
    function _recordWinners() internal virtual override {
        _recordWinner(_toJoinerIndex(_drawnPosition), getRewardAmount());
    }

    function _toJoinerIndex(uint256 position) internal pure returns (uint256) {
        return position - 1;
    }

    // #endregion

    // #region Private functions

    //

    // #endregion
}
