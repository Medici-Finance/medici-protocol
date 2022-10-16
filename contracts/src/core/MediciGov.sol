pragma solidity 0.8.15;

import {MediciState} from "./MediciState.sol";

contract MediciGov is MediciState {
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setNonce() public onlyOwner  {
        _state.nonce = 0;
    }

    /// @dev registerChain serves to save periphery contract addresses in core state
    function registerChain(uint16 periChainID, bytes32 periAddr) public onlyOwner {
        require(periAddr != bytes32(0), "Invalid address");
        setPeripheryContract(periChainID, periAddr);
    }
}
