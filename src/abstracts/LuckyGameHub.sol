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
    mapping(address => GameInfo) _createdGames;
    /**
     *
     */

    address[] _games;

    /**
     *
     */
    event GameCreated(address actor, address game);

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
        address game = _create();

        _createdGames[game].createdAt = block.timestamp;
        _games.push(game);

        emit GameCreated(_msgSender(), game);

        return game;
    }

    /**
     *
     */
    function _create() internal virtual returns (address);

    /**
     *
     */
    function _retrieveGameContract(address game)
        internal
        pure
        virtual
        returns (ILuckyGame);
}
