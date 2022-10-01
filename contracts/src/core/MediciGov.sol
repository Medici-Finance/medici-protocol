pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import {MediciState} from "./MediciState.sol";

contract MediciGov is MediciState, ERC1967Upgrade {

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev registerChain serves to save periphery contract addresses in core state
    function registerChain(uint16 periChainID, bytes32 periAddr) public onlyOwner {
        require(periAddr != bytes32(0), "Invalid address");
        require(getPeripheryContract(periChainID) == bytes32(0), "Chain already registered");
        setPeripheryContract(periChainID, periAddr);
    }
}
