// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "../src/MediciPool.sol";
import "./HelperConfig.sol";

contract DeployMediciPool is Script {
    uint8 constant DECIMALS = 18;
    address usdc_goerli_address = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    function run() external {
        vm.startBroadcast();
        ERC20 usdcToken = ERC20(usdc_goerli_address);
        // Personhood ph = new Personhood(HelperConfig.worldID);
        MediciPool pool = new MediciPool(usdcToken, address(usdcToken));
        vm.stopBroadcast();
    }
}
