// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/HasBalance.sol";
import "../interfaces/ILuckyGame.sol";
import "../interfaces/ILuckyGameHub.sol";
import "./HubOwned.sol";

/**
 *
 */
abstract contract LuckyGame is ILuckyGame, HubOwned, HasBalance {
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

    /**
     *
     */
    bool _paused;

    /**
     *
     */
    uint256 internal _ticketPrice;

    /**
     * @dev Percentage value, range = [0, 100].
     */
    uint256 internal _ticketFeeRate;

    /**
     *
     */
    uint256 internal _startAt;

    /**
     *
     */
    uint256 internal _endAt;

    /**
     *
     */
    uint256 internal _baseRewardAmount;

    /**
     *
     */
    uint256 internal _sumTickets;

    /**
     *
     */
    address[] internal _joiners;

    /**
     *
     */
    address[] internal _winners;

    /**
     *
     */
    mapping(address => uint256) internal _winningAmounts;

    /**
     *
     */
    DrawState _drawState;

    /**
     *
     */
    event TimeUpdated(address actor, uint256 startAt, uint256 endAt);

    /**
     *
     */
    event Joined(address actor, uint256 sumTickets);

    /**
     *
     */
    event Drawn(address actor);

    /**
     *
     */
    event Recorded(address actor);

    /**
     *
     */
    event Rewarded(
        address actor,
        uint256 count,
        uint256 amount,
        uint256 balanceBefore,
        uint256 balanceAfter
    );

    /**
     *
     */
    event Withdrawn(address actor, address to, uint256 amount);

    /**
     *
     */
    constructor(
        ILuckyGameHub hubContract,
        uint256 ticketPrice,
        uint256 ticketFeeRate,
        uint256 startAt,
        uint256 endAt,
        uint256 baseRewardAmount
    ) HubOwned(hubContract) {
        require(
            baseRewardAmount > ticketPrice,
            "The base rewarding amount should be logically bigger than the ticket price."
        );
        require(
            ticketFeeRate <= 100,
            "Rate should be in the range from 0 to 100."
        );

        _paused = false;
        _drawState = DrawState.NOT_DRAWN;
        _sumTickets = 0;

        _ticketPrice = ticketPrice;
        _ticketFeeRate = ticketFeeRate;
        _setTime(startAt, endAt);
        _baseRewardAmount = baseRewardAmount;
    }

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
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     *
     */
    function rewardReady() public view returns (bool) {
        return getBalance() >= _baseRewardAmount;
    }

    /**
     *
     */
    function getIncome() public view returns (uint256) {
        return _sumTickets * _ticketPrice;
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
    function getRewardAmount() public view returns (uint256) {
        return _baseRewardAmount + (getIncome() - getFees());
    }

    /**
     *
     */
    function getWinners() public view returns (address[] memory) {
        return _winners;
    }

    /**
     *
     */
    function getWinningAmount(address winner) public view returns (uint256) {
        return _winningAmounts[winner];
    }

    /**
     *
     */
    function setTime(uint256 startAt, uint256 endAt) public onlyHub {
        _setTime(startAt, endAt);
        emit TimeUpdated(_msgSender(), _startAt, _endAt);
    }

    /**
     *
     */
    function setUnlimitedTime() public onlyHub {
        setTime(0, 0);
    }

    /**
     *
     */
    function setStartTime(uint256 startAt) public onlyHub {
        setTime(startAt, _endAt);
    }

    /**
     *
     */
    function setEndTime(uint256 endAt) public onlyHub {
        setTime(_startAt, endAt);
    }

    /**
     *
     */
    function endNow() public onlyHub {
        setTime(_startAt, block.timestamp);
    }

    /**
     *
     */
    function pause() public onlyHub {
        _paused = true;
    }

    /**
     *
     */
    function resume() public onlyHub {
        _paused = false;
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
        emit Recorded(_msgSender());
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
        uint256 rewarded = 0;
        uint256 rewardedAmount = 0;
        if (_winners.length > 0) {
            address winner;
            uint256 winningAmount;
            for (uint256 i = 0; i < _winners.length; ++i) {
                winner = _winners[i];
                winningAmount = _winningAmounts[winner];
                if (winningAmount > 0) {
                    require(
                        balanceAfter >= winningAmount,
                        "Insuficient funds."
                    );

                    payable(winner).transfer(winningAmount);
                    rewarded += 1;
                    rewardedAmount += rewardedAmount;

                    // update balance after
                    balanceAfter = getBalance();
                }
            }
        }

        // Checkpoint to make sure the current balance is fine
        assert(balanceAfter == balanceBefore - rewardedAmount);

        _drawState = DrawState.REWARDED;

        emit Rewarded(
            _msgSender(),
            rewarded,
            rewardedAmount,
            balanceBefore,
            balanceAfter
        );
    }

    /**
     * @dev Return money to the hub
     */
    function withdraw() external {
        if (_drawState != DrawState.REWARDED) {
            return;
        }
        uint256 withdrawingAmount = getBalance();
        if (withdrawingAmount == 0) {
            return;
        }

        _checkHubOwned();

        address to = hub();
        payable(to).transfer(withdrawingAmount);
        emit Withdrawn(_msgSender(), to, withdrawingAmount);
    }

    /**
     *
     */
    function _setTime(uint256 startAt, uint256 endAt) internal {
        require(
            _drawState == DrawState.NOT_DRAWN,
            "Drawn! The time range will no longer be updated."
        );
        // Valid: 0 ~ 0, x ~ y (x < y)
        require(
            (startAt == 0 && endAt == 0) || (startAt < endAt),
            "The time range is invalid."
        );

        _startAt = startAt;
        _endAt = endAt;
    }

    /**
     *
     */
    function _randomizeTicket() internal virtual returns (string memory);

    /**
     *
     */
    function _join(address joiner, string memory ticket) internal {
        // Make sure the base rewarding amount is ready
        require(rewardReady(), "Unavailable to join now. Please wait.");
        // Check time range
        require(inTime() && _drawState == DrawState.NOT_DRAWN, "Out of time.");
        // Is paused?
        require(!_paused, "Joining is temporarily disabled.");
        // Sending exact amount to buy ticket?
        require(
            msg.value == _ticketPrice,
            "The sending fund is not matched to buy a ticket."
        );

        _joining(joiner, ticket);

        _joiners.push(joiner);
        ++_sumTickets;
        emit Joined(joiner, _sumTickets);
    }

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
}
