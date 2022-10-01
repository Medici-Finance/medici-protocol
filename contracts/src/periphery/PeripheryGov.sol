pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import {PeripheryState} from "./PeripheryState.sol";

contract PeripheryGov is PeripheryState, ERC1967Upgrade {
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}
