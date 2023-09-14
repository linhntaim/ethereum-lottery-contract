// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/ILuckyGameHub.sol";

/**
 *
 */
abstract contract HubOwned is Context {
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
     *
     */
    ILuckyGameHub private _hubContract;

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
    constructor(ILuckyGameHub hubContract) {
        _hubContract = hubContract;
    }

    // #endregion

    // #region Modifiers

    /**
     *
     */
    modifier onlyHub() {
        _checkHub();
        _checkHubOwned();
        _;
    }

    // #endregion

    // #region Fallback functions

    //

    // #endregion

    // #region External functions

    //

    // #endregion

    // #region Public functions

    /**
     *
     */
    function hub() public view virtual returns (address) {
        return address(_hubContract);
    }

    // #endregion

    // #region Internal functions

    /**
     *
     */
    function _checkHub() internal view {
        require(hub() == _msgSender(), "Caller is not the hub.");
    }

    /**
     *
     */
    function _checkHubOwned() internal view virtual {
        require(
            _hubContract.owned(address(this)),
            "The hub does not own this contract."
        );
    }

    // #endregion

    // #region Private functions

    //

    // #endregion
}
