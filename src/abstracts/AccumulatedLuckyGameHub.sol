// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LuckyGameHub.sol";

/**
 *
 */
abstract contract AccumulatedLuckyGameHub is LuckyGameHub {
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
     * @dev Percentage value, range = [0, 100].
     */
    uint256 private _reserveRate;

    // #endregion

    // #region Events

    //

    // #endregion

    // #region Errors

    //

    // #endregion

    // #region Constructor

    constructor(
        uint256 baseRewardAmount,
        uint256 ticketPrice,
        uint256 ticketFeeRate,
        uint256 reserveRate
    ) LuckyGameHub(baseRewardAmount, ticketPrice, ticketFeeRate) {
        require(
            reserveRate <= 100,
            "Rates must be in the range from 0 to 100."
        );

        _reserveRate = reserveRate;
    }

    // #endregion

    // #region Modifiers

    //

    // #endregion

    // #region Fallback functions

    //

    // #endregion

    // #region External functions

    /**
     *
     */
    function getReserveRate() external view returns (uint256) {
        return _reserveRate;
    }

    // #endregion

    // #region Public functions

    //

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _calcReserveBasedOnGameReward(uint256 rewardAmount)
        internal
        view
        override
        returns (uint256)
    {
        return ((rewardAmount - getBaseRewardAmount()) * _reserveRate) / 100;
    }

    /**
     *
     */
    function _creatingRewardAmount() internal override returns (uint256) {
        uint256 baseRewardAmount = getBaseRewardAmount();
        uint256 balance = getBalance();

        // Collect accumulated reward before creating a game
        if (balance > baseRewardAmount + _reserve + _profits) {
            // Not enough base reward, so accumulated reward must be min (= base reward)
            // Collect its amount from reserve or profits when needed
            uint256 underAmount = balance -
                (baseRewardAmount + _reserve + _profits);
            if (_reserve >= underAmount) {
                // Enough fund in reserve
                _reserve -= underAmount;
            } else {
                // If not enough fund in reserve, pull out all
                _reserve = 0;
                // And take the rest from profits
                underAmount = underAmount - _reserve;
                _profits -= underAmount; // _profits is always larger than underAmount, so no need to worry
            }

            return baseRewardAmount;
        }

        return balance - _reserve - _profits;
    }

    // #endregion

    // #region Private functions

    //

    // #endregion
}
