pragma solidity 0.8.15;

import {PeripheryState} from "./PeripheryState.sol";

contract PeripheryGov is PeripheryState {
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function registerCore(uint16 coreChainID, bytes32 coreAddr) public onlyOwner {
        require(coreAddr != bytes32(0), "Invalid address");
        setCoreContract(coreChainID, coreAddr);
    }
}
