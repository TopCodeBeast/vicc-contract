// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CapperAccess is Ownable, AccessControl {
    bytes32 public constant CAPPER_ROLE = keccak256("CAPPER_ROLE");

    modifier onlyCapper {
        require(hasRole(CAPPER_ROLE, _msgSender()), "Sender is not a capper");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CAPPER_ROLE, msg.sender);
    }

    function addCapper(address account) external {
        grantRole(CAPPER_ROLE, account);
    }

    function renounceCapper(address account) external {
        renounceRole(CAPPER_ROLE, account);
    }
}