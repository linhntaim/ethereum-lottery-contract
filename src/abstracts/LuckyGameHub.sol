// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILuckyGame.sol";
import "../interfaces/ILuckyGameHub.sol";
import "../utils/HasBalance.sol";

/**
 *
 */
abstract contract LuckyGameHub is ILuckyGameHub, Ownable, HasBalance {
    // #region Types

    /**
     *
     */
    struct GameInfo {
        /**
         *
         */
        uint256 createdAt;
    }

    // #endregion

    // #region Public states

    //

    // #endregion

    // #region Internal states

    /**
     *
     */
    uint256 internal _reserve;

    /**
     *
     */
    uint256 internal _profits;

    // #endregion

    // #region Private states

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
    address[] private _games;

    /**
     *
     */
    mapping(address => GameInfo) private _createdGames;

    // #endregion

    // #region Events

    /**
     *
     */
    event GameCreated(address actor, address game);

    /**
     *
     */
    event Withdrawn(address actor, address to, uint256 amount);

    /**
     *
     */
    event Deposited(address actor, uint256 amount);

    // #endregion

    // #region Errors

    //

    // #endregion

    // #region Constructor

    constructor(
        uint256 baseRewardAmount,
        uint256 ticketPrice,
        uint256 ticketFeeRate
    ) {
        require(
            baseRewardAmount > ticketPrice,
            "The base rewarding amount should be logically bigger than the ticket price."
        );
        require(
            ticketFeeRate <= 100,
            "Rates must be in the range from 0 to 100."
        );

        _reserve = 0;
        _profits = 0;

        _baseRewardAmount = baseRewardAmount;
        _ticketPrice = ticketPrice;
        _ticketFeeRate = ticketFeeRate;
    }

    // #endregion

    // #region Modifiers

    //

    // #endregion

    // #region Fallback functions

    /**
     *
     */
    receive() external payable {
        uint256 balance = getBalance();

        address sender = _msgSender();
        uint256 depositingAmount = msg.value;

        if (owned(sender)) {
            // Return from created game
            _updateFundsFromGameDeposit(
                depositingAmount,
                _retrieveGameContract(sender).getFees()
            );
        } else {
            // Others will be considered as profits
            _profits += depositingAmount;
        }

        assert(_reserve + _profits <= balance);

        emit Deposited(sender, depositingAmount);
    }

    // #endregion

    // #region External functions

    /**
     *
     */
    function getReserve() external view returns (uint256) {
        return _reserve;
    }

    /**
     *
     */
    function getProfits() external view returns (uint256) {
        return _profits;
    }

    /**
     *
     */
    function create() external returns (address) {
        require(
            getBalance() >= _baseRewardAmount,
            "Not enough funds to create a game."
        );

        address game = _create(_creatingRewardAmount());

        _createdGames[game].createdAt = block.timestamp;
        _games.push(game);

        emit GameCreated(_msgSender(), game);

        return game;
    }

    /**
     * @dev Withdraw profits to owner address.
     */
    function withdraw() external onlyOwner {
        if (_profits > 0) {
            uint256 amount = _profits;
            _profits = 0;
            address to = owner();
            payable(to).transfer(amount);
            emit Withdrawn(_msgSender(), to, amount);
        }
    }

    // #endregion

    // #region Public functions

    /**
     *
     */
    function getBaseRewardAmount() public view returns (uint256) {
        return _baseRewardAmount;
    }

    /**
     *
     */
    function getTicketPrice() public view returns (uint256) {
        return _ticketPrice;
    }

    /**
     *
     */
    function getTicketFeeRate() public view returns (uint256) {
        return _ticketFeeRate;
    }

    /**
     *
     */
    function latest() public view virtual returns (address) {
        require(_games.length > 0, "No game now.");
        return _games[_games.length - 1];
    }

    /**
     *
     */
    function owned(address game) public view returns (bool) {
        return _createdGames[game].createdAt != 0;
    }

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _updateFundsFromGameDeposit(uint256 gameFunds, uint256 gameFees)
        internal
    {
        require(
            gameFees <= gameFunds,
            "Something wrong with the game's deposit."
        );
        _profits += gameFees;

        // - Update reserve
        if (gameFunds > gameFees) {
            uint256 gameReward = gameFunds - gameFees;
            if (gameReward > _baseRewardAmount) {
                _reserve += _calcReserveBasedOnGameReward(gameReward);
            }
        }
    }

    /**
     *
     */
    function _calcReserveBasedOnGameReward(uint256 rewardAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        return rewardAmount - _baseRewardAmount;
    }

    /**
     *
     */
    function _creatingRewardAmount() internal virtual returns (uint256) {
        return _baseRewardAmount;
    }

    /**
     *
     */
    function _create(uint256 creatingRewardAmount)
        internal
        virtual
        returns (address);

    /**
     *
     */
    function _retrieveGameContract(address game)
        internal
        pure
        virtual
        returns (ILuckyGame);

    // #endregion

    // #region Private functions

    //

    // #endregion
}
