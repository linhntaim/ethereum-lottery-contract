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
    /**
     *
     */
    struct GameInfo {
        /**
         *
         */
        uint256 createdAt;
    }

    /**
     *
     */
    uint256 internal _ticketPrice = 10**18 / 100; // 0.01 coin

    /**
     * @dev Percentage value, range = [0, 100].
     */
    uint256 internal _ticketFeeRate = 10; // 10%

    /**
     *
     */
    uint256 internal _baseRewardAmount = 10**18; // 1 coin

    /**
     * @dev Percentage value, range = [0, 100].
     */
    uint256 internal _reserveRate = 20; // 20%

    /**
     *
     */
    uint256 private _reserve = 0;

    /**
     *
     */
    uint256 private _profits = 0;

    /**
     *
     */
    address[] private _games;

    /**
     *
     */
    mapping(address => GameInfo) private _createdGames;

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
    function latestContract() public view returns (ILuckyGame) {
        return _retrieveGameContract(latest());
    }

    /**
     *
     */
    function owned(address game) public view returns (bool) {
        return _createdGames[game].createdAt != 0;
    }

    /**
     *
     */
    function create() external returns (address) {
        uint256 balance = getBalance();
        require(
            balance >= _baseRewardAmount,
            "Not enough funds to create a game."
        );

        // Collect accumulated reward before creating a game
        uint256 accumulatedRewardAmount = 0;
        if (balance > _baseRewardAmount + _reserve + _profits) {
            // Not enough base reward, so accumulated reward must be min (= base reward)
            // Collect its amount from reserve or profits when needed
            uint256 underAmount = balance -
                (_baseRewardAmount + _reserve + _profits);
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

            accumulatedRewardAmount = _baseRewardAmount;
        } else {
            // Enough base reward, accumulated reward is the amount not in both reserve and profits
            accumulatedRewardAmount = balance - _reserve - _profits;
        }

        address game = _create(accumulatedRewardAmount);

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
            uint256 withdrawingAmount = _profits;
            _profits = 0;
            address to = owner();
            payable(to).transfer(withdrawingAmount);
            emit Withdrawn(_msgSender(), to, withdrawingAmount);
        }
    }

    /**
     *
     */
    receive() external payable {
        uint256 balance = getBalance();

        address sender = _msgSender();
        uint256 depositingAmount = msg.value;

        if (owned(sender)) {
            // Return from created game
            // Amount = Reward + Fees

            // - Update profits
            uint256 fees = _retrieveGameContract(sender).getFees();
            require(
                fees <= depositingAmount,
                "Something wrong with the game's deposit."
            );
            _profits += fees;

            // - Update reserve
            if (depositingAmount > fees) {
                uint256 reward = depositingAmount - fees;
                if (reward > _baseRewardAmount) {
                    _reserve +=
                        ((reward - _baseRewardAmount) * _reserveRate) /
                        100;
                }
            }
        } else {
            // Others will be considered as profits
            _profits += depositingAmount;
        }

        assert(_reserve + _profits <= balance);

        emit Deposited(sender, depositingAmount);
    }

    /**
     *
     */
    function _create(uint256 accumulatedRewardAmount)
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
}
