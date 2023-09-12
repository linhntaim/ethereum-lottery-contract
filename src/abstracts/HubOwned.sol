// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/ILuckyGameHub.sol";

/**
 *
 */
abstract contract HubOwned is Context {
    /**
     *
     */
    ILuckyGameHub internal _hub;

    /**
     *
     */
    constructor(ILuckyGameHub hub) {
        _hub = hub;
    }

    /**
     *
     */
    modifier onlyHub() {
        _checkHub();
        _checkHubOwned();
        _;
    }

    /**
     *
     */
    function hubAddress() public view virtual returns (address) {
        return address(_hub);
    }

    /**
     *
     */
    function _checkHub() internal view {
        require(hubAddress() == _msgSender(), "Caller is not the hub.");
    }

    /**
     *
     */
    function _checkHubOwned() internal view virtual {
        require(_hub.owned(address(this)), "The hub does not own this contract.");
    }
}
