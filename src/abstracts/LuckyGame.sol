// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILuckyGame.sol";
import "../interfaces/ILuckyGameHub.sol";
import "../utils/AddressList.sol";
import "../utils/HasBalance.sol";
import "./HubOwned.sol";

/**
 *
 */
abstract contract LuckyGame is ILuckyGame, HubOwned, HasBalance {
    // #region Types

    using AddressListMethods for AddressList;

    /**
     *
     */
    enum DrawState {
        NOT_DRAWN,
        DRAWING,
        DRAWN,
        RECORDING,
        RECORDED,
        REWARDING,
        REWARDED
    }

    // #endregion

    // #region Public states

    //

    // #endregion

    // #region Internal states

    //

    // #endregion

    // #region Private states

    /**
     *
     */
    bool private _onetimeLimited;

    /**
     *
     */
    uint256 private _startAt;

    /**
     *
     */
    uint256 private _endAt;

    /**
     *
     */
    uint256 private _baseRewardAmount;

    /**
     *
     */
    uint256 private _ticketPrice;

    /**
     * @dev Percentage value, range = [0, 100].
     */
    uint256 private _ticketFeeRate;

    /**
     *
     */
    AddressList private _joiners;

    /**
     *
     */
    AddressList private _winners;

    /**
     *
     */
    DrawState private _drawState;

    // #endregion

    // #region Events

    /**
     *
     */
    event TimeUpdated(address actor, uint256 startAt, uint256 endAt);

    /**
     *
     */
    event Joined(
        address actor,
        string ticket,
        uint256 countJoiners,
        uint256 countTickets
    );

    /**
     *
     */
    event Drawn(address actor);

    /**
     *
     */
    event Recorded(
        address actor,
        uint256 countWinners,
        uint256 rewardingAmount
    );

    /**
     *
     */
    event Rewarded(address actor, uint256 balanceBefore, uint256 balanceAfter);

    /**
     *
     */
    event Withdrawn(address actor, address to, uint256 amount);

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
        uint256 ticketFeeRate,
        bool onetimeLimited
    ) HubOwned(hubContract) {
        require(
            (startAt == 0 && endAt == 0) || (startAt < endAt),
            "The time range is invalid." // Valid: 0 ~ 0, x ~ y (x < y)
        );
        require(
            baseRewardAmount > ticketPrice,
            "The base reward amount should be logically bigger than the ticket price."
        );
        require(
            ticketFeeRate <= 100,
            "Rate must be in the range from 0 to 100."
        );

        _drawState = DrawState.NOT_DRAWN;

        _startAt = startAt;
        _endAt = endAt;
        _baseRewardAmount = baseRewardAmount;
        _ticketPrice = ticketPrice;
        _ticketFeeRate = ticketFeeRate;
        _onetimeLimited = onetimeLimited;
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
    function getStartAt() external view returns (uint256) {
        return _startAt;
    }

    /**
     *
     */
    function getEndAt() external view returns (uint256) {
        return _endAt;
    }

    /**
     *
     */
    function getBaseRewardAmount() external view returns (uint256) {
        return _baseRewardAmount;
    }

    /**
     *
     */
    function getTicketPrice() external view returns (uint256) {
        return _ticketPrice;
    }

    /**
     *
     */
    function getTicketFeeRate() external view returns (uint256) {
        return _ticketFeeRate;
    }

    /**
     *
     */
    function isWinner(address someone) external view returns (bool) {
        return _winners.has(someone);
    }

    /**
     *
     */
    function getState() external view returns (string memory) {
        if (_drawState == DrawState.DRAWING) {
            return "drawing";
        }
        if (_drawState == DrawState.DRAWN) {
            return "drawn";
        }
        if (_drawState == DrawState.RECORDING) {
            return "recording";
        }
        if (_drawState == DrawState.RECORDED) {
            return "recorded";
        }
        if (_drawState == DrawState.REWARDING) {
            return "rewarding";
        }
        if (_drawState == DrawState.REWARDED) {
            return "rewarded";
        }

        // Draw state: Not drawn
        if (block.timestamp < _startAt) {
            return "not_started";
        }
        if (block.timestamp > _endAt) {
            return "ended";
        }
        return "opening";
    }

    /**
     *
     */
    function join() external payable {
        _join(_msgSender(), _randomizeTicket());
    }

    /**
     *
     */
    function join(address joiner) external payable {
        _join(joiner, _randomizeTicket());
    }

    /**
     *
     */
    function join(string memory ticket) external payable {
        _join(_msgSender(), ticket);
    }

    /**
     *
     */
    function join(address joiner, string memory ticket) external payable {
        _join(joiner, ticket);
    }

    /**
     *
     */
    function draw() external {
        require(block.timestamp > _endAt, "Cannot draw now.");
        require(
            _drawState == DrawState.NOT_DRAWN,
            "Drawn! Cannot run it again."
        );

        _drawState = DrawState.DRAWING;
        _draw();
        _drawState = DrawState.DRAWN;
        emit Drawn(_msgSender());
    }

    /**
     *
     */
    function recordWinners() external {
        if (_drawState != DrawState.DRAWN) {
            return;
        }

        _drawState = DrawState.RECORDING;
        _recordWinners();
        _drawState = DrawState.RECORDED;
        emit Recorded(_msgSender(), _winners.length(), _winners.sumValues);
    }

    /**
     *
     */
    function rewardWinners() external {
        if (_drawState != DrawState.RECORDED) {
            return;
        }

        _drawState = DrawState.REWARDING;

        uint256 balanceBefore = getBalance();
        uint256 balanceAfter = balanceBefore;

        // Execute rewarding
        uint256 countWinners_ = countWinners();
        if (countWinners_ > 0) {
            address winner;
            uint256 rewardAmount;
            for (uint256 i = 0; i < countWinners_; ++i) {
                winner = _winners.addresses[i];
                rewardAmount = _winners.values[winner];

                require(balanceAfter >= rewardAmount, "Insuficient funds.");
                payable(winner).transfer(rewardAmount);

                // update balance after
                balanceAfter = getBalance();
            }
        }

        // Checkpoint to make sure the current balance is fine
        assert(balanceAfter == balanceBefore - _winners.sumValues);

        _drawState = DrawState.REWARDED;

        emit Rewarded(_msgSender(), balanceBefore, balanceAfter);
    }

    /**
     * @dev Return money to the hub
     */
    function withdraw() external {
        if (_drawState != DrawState.REWARDED) {
            return;
        }
        uint256 balance = getBalance();
        if (balance == 0) {
            return;
        }

        _checkHubOwned();

        address to = hub();
        payable(to).transfer(balance);
        emit Withdrawn(_msgSender(), to, balance);
    }

    // #endregion

    // #region Public functions

    /**
     *
     */
    function inTime() public view returns (bool) {
        return
            (_startAt == 0 && _endAt == 0) ||
            (block.timestamp >= _startAt && block.timestamp <= _endAt);
    }

    /**
     *
     */
    function countJoiners() public view returns (uint256) {
        return _joiners.length();
    }

    /**
     *
     */
    function isJoiner(address someone) public view returns (bool) {
        return _joiners.has(someone);
    }

    /**
     *
     */
    function countTickets() public view returns (uint256) {
        return _joiners.sumValues;
    }

    /**
     *
     */
    function countWinners() public view returns (uint256) {
        return _winners.length();
    }

    /**
     *
     */
    function getIncome() public view returns (uint256) {
        return countTickets() * _ticketPrice;
    }

    /**
     *
     */
    function getFees() public view returns (uint256) {
        return (getIncome() * _ticketFeeRate) / 100;
    }

    /**
     *
     */
    function getPerformanceRewardAmount() public view returns (uint256) {
        return getIncome() - getFees();
    }

    /**
     *
     */
    function getRewardAmount() public view returns (uint256) {
        return _baseRewardAmount + getPerformanceRewardAmount();
    }

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _randomizeTicket() internal virtual returns (string memory);

    /**
     *
     */
    function _joining(address joiner, string memory ticket) internal virtual;

    /**
     *
     */
    function _draw() internal virtual;

    /**
     *
     */
    function _recordWinners() internal virtual;

    /**
     *
     */
    function _recordWinner(uint256 joinerIndex, uint256 rewardAmount) internal {
        _recordWinner(_joiners.addresses[joinerIndex], rewardAmount);
    }

    /**
     *
     */
    function _recordWinner(address winner, uint256 rewardAmount) internal {
        _winners.add(winner, rewardAmount);
    }

    // #endregion

    // #region Private functions

    /**
     *
     */
    function _join(address joiner, string memory ticket) private {
        // Make sure the base reward is ready
        require(
            getBalance() >= _baseRewardAmount,
            "Base reward has not been ready yet. Please wait."
        );
        // Check time range
        require(inTime(), "Out of time.");
        // Prevent joiners from joining multiple times when flagged
        require(
            _onetimeLimited && isJoiner(joiner),
            "You have already joined."
        );
        // Sending exact price amount to buy ticket?
        require(
            msg.value == _ticketPrice,
            "The sending fund is not matched to buy a ticket."
        );

        _joining(joiner, ticket);

        _joiners.add(joiner);
        emit Joined(joiner, ticket, _joiners.length(), countTickets());
    }

    // #endregion
}
