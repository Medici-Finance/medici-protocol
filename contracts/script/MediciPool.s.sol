// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { MediciPool } from "../src/MediciPool.sol";
import { RiskManager } from "../src/RiskManager.sol";
import "./HelperConfig.sol";

contract DeployMediciPool is Script {
    uint8 constant DECIMALS = 18;
    address usdc_mumbai_address = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
    address personhood_mumbai= 0x3722715eBDD73201809986c84b31ffF4b8171fE7;

    function run() external {
        vm.startBroadcast();
        RiskManager rm = new RiskManager();
        // Personhood ph = new Personhood(HelperConfig.worldID);
        MediciPool pool = new MediciPool(usdc_mumbai_address, personhood_mumbai, address(rm), 90, 2e17);
        vm.stopBroadcast();
    }
}
