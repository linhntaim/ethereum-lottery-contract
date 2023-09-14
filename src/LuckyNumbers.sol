// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./abstracts/LuckyGame.sol";
import "./interfaces/ILuckyGameHub.sol";
import "./utils/AddressList.sol";
import "./utils/random/INumberRoller.sol";

/**
 *
 */
contract LuckyNumbers is LuckyGame {
    // #region Types

    using AddressListMethods for AddressList;

    // #endregion

    // #region Public states

    //

    // #endregion

    // #region Internal states

    /**
     *
     */
    uint256[] internal _drawnTicketNums;

    /**
     * @dev Ticket => (Joiners, Joiner => Time)
     */
    mapping(string => AddressList) private _joinedTickets;

    // #endregion

    // #region Private states

    /**
     *
     */
    bool private _ticketNumRepetitionEnabled;

    /**
     *
     */
    bool private _ticketNumOrderMattered;

    /**
     * @dev Min = 1
     */
    uint256 private _ticketNumCount;

    /**
     *
     */
    INumberRoller private _numberRollerContract;

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
        uint256 ticketFeeRate,
        uint256 ticketNumCount,
        bool ticketNumRepetitionEnabled,
        bool ticketNumOrderMattered,
        INumberRoller numberRollerContract
    )
        LuckyGame(
            hubContract,
            startAt,
            endAt,
            baseRewardAmount,
            ticketPrice,
            ticketFeeRate
        )
    {
        require(ticketNumCount > 0, "Ticket cannot be empty.");

        _ticketNumCount = ticketNumCount;
        _ticketNumRepetitionEnabled = ticketNumRepetitionEnabled;
        _ticketNumOrderMattered = ticketNumOrderMattered;
        _numberRollerContract = numberRollerContract;
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
    function getDrawnTicket() external view returns (string memory) {
        return
            _drawnTicketNums.length > 0 ? _rebuildTicket(_drawnTicketNums) : "";
    }

    // #endregion

    // #region Public functions

    /**
     *
     */
    function getTicketNumCount() public view returns (uint256) {
        return _ticketNumCount;
    }

    /**
     *
     */
    function getTicketNumRepetitionEnabled() public view returns (bool) {
        return _ticketNumRepetitionEnabled;
    }

    /**
     *
     */
    function getTicketNumOrderMattered() public view returns (bool) {
        return _ticketNumOrderMattered;
    }

    /**
     *
     */
    function getNumberRoller() public view returns (address) {
        return address(_numberRollerContract);
    }

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _randomizeTicket() internal override returns (string memory) {
        return _rebuildTicket(_randomizeTicketNums());
    }

    /**
     *
     */
    function _joining(address joiner, string memory ticket) internal override {
        _storeTicket(joiner, _parseTicket(ticket));
    }

    /**
     *
     */
    function _storeTicket(address joiner, uint256[] memory ticketNums)
        internal
        virtual
    {
        string memory joinedTicket = _buildJoinedTicket(ticketNums);
        _joinedTickets[joinedTicket].add(joiner);
    }

    /**
     *
     */
    function _buildJoinedTicket(uint256[] memory ticketNums)
        internal
        view
        returns (string memory)
    {
        return _rebuildTicket(_sortTicketNums(ticketNums));
    }

    /**
     *
     */
    function _rebuildTicket(uint256[] memory ticketNums)
        internal
        pure
        returns (string memory)
    {
        string memory ticket = Strings.toString(ticketNums[0]);
        for (uint256 i = 1; i < ticketNums.length; ++i) {
            ticket = string.concat(
                ticket,
                ";",
                Strings.toString(ticketNums[i])
            );
        }
        return ticket;
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
    function _draw() internal virtual override {
        _drawnTicketNums = _randomizeTicketNums();
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
                randomNum = _numberRollerContract.roll();

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
    function _recordWinners() internal virtual override {
        AddressList storage winningAddressList = _joinedTickets[
            _buildJoinedTicket(_drawnTicketNums)
        ];
        uint256 length = winningAddressList.length();
        if (length == 1) {
            _recordWinner(winningAddressList.addresses[0], getRewardAmount());
        } else if (length > 1) {
            mapping(address => uint256) storage mappingLots = winningAddressList
                .values;
            uint256 sumLots = winningAddressList.sumValues;
            uint256 rewardAmountPerLot = getRewardAmount() / sumLots;
            address winner;
            for (uint256 i = 0; i < length; ++i) {
                winner = winningAddressList.addresses[i];
                _recordWinner(winner, mappingLots[winner] * rewardAmountPerLot);
            }
        }
    }

    // #endregion

    // #region Private functions

    /**
     * @dev Ticket format: "/([0-9]+;?)+/".
     */
    function _parseTicket(string memory ticket)
        private
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
                    _numberRollerContract.valid(currentNum),
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

    // #endregion
}
