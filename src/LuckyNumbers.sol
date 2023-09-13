// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./abstracts/LuckyGame.sol";
import "./interfaces/ILuckyGameHub.sol";
import "./utils/JoiningList.sol";
import "./utils/random/INumberRoller.sol";

/**
 *
 */
contract LuckyNumbers is LuckyGame {
    using JoiningListMethods for JoiningList;

    /**
     * @dev Min = 1
     */
    uint256 internal _ticketNumCount;

    /**
     *
     */
    bool internal _ticketNumRepetitionEnabled;

    /**
     *
     */
    bool internal _ticketNumOrderMattered;

    /**
     *
     */
    INumberRoller internal _numberRoller;

    /**
     * @dev Ticket => (Joiners, Joiner => Time)
     */
    mapping(string => JoiningList) internal _joinedTickets;

    /**
     *
     */
    uint256[] internal _drawnTicketNums;

    /**
     *
     */
    constructor(
        ILuckyGameHub hubContract,
        uint256 ticketPrice,
        uint256 ticketFeeRate,
        uint256 startAt,
        uint256 endAt,
        uint256 baseRewardAmount,
        uint256 ticketNumCount,
        INumberRoller numberRoller,
        bool ticketNumRepetitionEnabled,
        bool ticketNumOrderMattered
    )
        LuckyGame(
            hubContract,
            ticketPrice,
            ticketFeeRate,
            startAt,
            endAt,
            baseRewardAmount
        )
    {
        require(ticketNumCount > 0, "Ticket cannot be empty.");

        _ticketNumCount = ticketNumCount;
        _numberRoller = numberRoller;
        _ticketNumRepetitionEnabled = ticketNumRepetitionEnabled;
        _ticketNumOrderMattered = ticketNumOrderMattered;
    }

    /**
     *
     */
    function getDrawnTicket() public view returns (string memory) {
        return
            _drawnTicketNums.length > 0 ? _rebuildTicket(_drawnTicketNums) : "";
    }

    /**
     * @dev Ticket format: "/([0-9]+;?)+/".
     */
    function _joining(address joiner, string memory ticket) internal override {
        uint256[] memory ticketNums = _parseTicket(ticket);
        string memory sortedTicket = _buildSortedTicket(ticketNums);
        for (uint256 i = 0; i < _ticketNumCount; ++i) {
            _joinedTickets[sortedTicket].insert(joiner);
        }
    }

    /**
     *
     */
    function _parseTicket(string memory ticket)
        internal
        view
        returns (uint256[] memory)
    {
        bytes memory chars = bytes(ticket);
        require(chars.length > 0, "Wrong ticket: Cannot be empty.");

        uint256[] memory ticketNums = new uint256[](_ticketNumCount);

        // Parse ticket to nums
        // - starting state
        bool digitRequired = true;
        uint256 currentNum = 0; // current parsed num
        uint256 parsed = 0; // parsing counter
        // - char loop
        uint256 i = 0;
        uint256 charCode;
        bool shouldStore;
        while (i++ < chars.length) {
            shouldStore = false;

            charCode = uint8(chars[i]);
            if ((charCode >= 48) && (charCode <= 57)) {
                // Meet number: [0-9], update current parsed num
                currentNum = currentNum * 10 + (charCode - 48);
                digitRequired = false;

                if (i == (chars.length - 1)) {
                    // Reach the end
                    shouldStore = true;
                }
            } else {
                // Should meet delimiter: [;]
                require(
                    !digitRequired && charCode == 59,
                    "Wrong ticket: Wrong format."
                );
                shouldStore = true;
            }

            if (shouldStore) {
                // Store current parsed num
                require(
                    _numberRoller.valid(currentNum),
                    "Wrong ticket: Unaccepted number found."
                );
                if (!_ticketNumRepetitionEnabled) {
                    for (uint256 j = 0; j < parsed; ++j) {
                        require(
                            ticketNums[i] != currentNum,
                            "Wrong ticket: Repetition of numbers is not allowed."
                        );
                    }
                }
                ticketNums[parsed] = currentNum;
                ++parsed;
                if (parsed == _ticketNumCount && i < chars.length - 1) {
                    // Error: Nums is fulfilled but the ticket has more to parse
                    revert("Wrong ticket: Numbers exceeded.");
                }
                // Reset
                digitRequired = true;
                currentNum = 0;
            }
        }
        return ticketNums;
    }

    /**
     *
     */
    function _sortTicketNums(uint256[] memory ticketNums)
        internal
        view
        returns (uint256[] memory)
    {
        if (!_ticketNumOrderMattered) {
            uint256 i;
            uint256 j;
            uint256 n;
            for (i = 0; i < _ticketNumCount - 1; ++i) {
                for (j = i + 1; j < _ticketNumCount; ++j) {
                    if (ticketNums[j] > ticketNums[i]) {
                        n = ticketNums[i];
                        ticketNums[i] = ticketNums[j];
                        ticketNums[j] = n;
                    }
                }
            }
        }
        return ticketNums;
    }

    /**
     *
     */
    function _rebuildTicket(uint256[] memory ticketNums)
        internal
        pure
        returns (string memory)
    {
        string memory joinedTicket = Strings.toString(ticketNums[0]);
        for (uint256 i = 1; i < ticketNums.length; ++i) {
            joinedTicket = string.concat(
                joinedTicket,
                ";",
                Strings.toString(ticketNums[i])
            );
        }
        return joinedTicket;
    }

    /**
     *
     */
    function _buildSortedTicket(uint256[] memory ticketNums)
        internal
        view
        returns (string memory)
    {
        return _rebuildTicket(_sortTicketNums(ticketNums));
    }

    /**
     *
     */
    function _randomizeTicketNums() internal returns (uint256[] memory) {
        uint256[] memory randomNums = new uint256[](_ticketNumCount);
        uint256 randomNum;
        uint256 i;
        uint256 j;
        bool repetitionFound;
        for (i = 0; i < _ticketNumCount; ++i) {
            repetitionFound = true;
            while (repetitionFound) {
                randomNum = _numberRoller.roll();

                repetitionFound = false;
                if (!_ticketNumRepetitionEnabled) {
                    for (j = 0; j < i; ++j) {
                        if (randomNums[j] == randomNum) {
                            repetitionFound = true;
                            break;
                        }
                    }
                }
            }

            randomNums[i] = randomNum;
        }
        return randomNums;
    }

    /**
     *
     */
    function _randomizeTicket() internal override returns (string memory) {
        return _rebuildTicket(_randomizeTicketNums());
    }

    /**
     *
     */
    function _draw() internal override {
        _drawnTicketNums = _randomizeTicketNums();
    }

    /**
     *
     */
    function _recordWinners() internal override {
        string memory drawnSortedTicket = _buildSortedTicket(_drawnTicketNums);
        JoiningList storage winningList = _joinedTickets[drawnSortedTicket];

        if (winningList.joiners.length > 0) {
            _winners = winningList.joiners;

            mapping(address => uint256) storage mappingLots = winningList.times;
            uint256 totalLots = winningList.sumTimes;
            uint256 winningAmountPerLot = getRewardAmount() / totalLots;
            for (uint256 i = 0; i < _winners.length; ++i) {
                _winningAmounts[_winners[i]] =
                    winningAmountPerLot *
                    mappingLots[_winners[i]];
            }
        }
    }
}
