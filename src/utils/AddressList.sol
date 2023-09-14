// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 */
struct AddressList {
    /**
     *
     */
    address[] addresses;
    /**
     *
     */
    mapping(address => uint256) values;
    /**
     *
     */
    uint256 sumValues;
}

/**
 *
 */
library AddressListMethods {
    /**
     *
     */
    function length(AddressList storage list) public view returns (uint256) {
        return list.addresses.length;
    }

    /**
     *
     */
    function has(AddressList storage list, address address_)
        public
        view
        returns (bool)
    {
        return list.values[address_] != 0;
    }

    /**
     *
     */
    function add(AddressList storage list, address address_) public {
        add(list, address_, 1);
    }

    /**
     *
     */
    function add(
        AddressList storage list,
        address address_,
        uint256 value_
    ) public {
        require(value_ > 0);
        if (!has(list, address_)) {
            list.addresses.push(address_);
        }
        list.values[address_] += value_;
        list.sumValues += value_;
    }
}
