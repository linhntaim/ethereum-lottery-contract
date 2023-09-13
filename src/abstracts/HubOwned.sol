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
    ILuckyGameHub internal _hubContract;

    /**
     *
     */
    constructor(ILuckyGameHub hubContract) {
        _hubContract = hubContract;
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
    function hub() public view virtual returns (address) {
        return address(_hubContract);
    }

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
        require(_hubContract.owned(address(this)), "The hub does not own this contract.");
    }
}
