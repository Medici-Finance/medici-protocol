pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "./LocalConfig.sol";
import "../src/core/MediciCore.sol";
import "../src/periphery/Periphery.sol";

contract Medici is Script {
    LocalConfig config;
    MediciCore core;
    Periphery periphery;
    string Xconfig = vm.readFile("../xdapp.config.json");


    function run() public {
        string memory password = vm.parseJson(Xconfig, "key");
        console.log(password);
    }

    function deployCore() public {
        uint256 deployerPrivateKey = vm.envUint("${local.polygon.deployerPrivateKey}");
        vm.startBroadcast();
        config = new LocalConfig();
        core = new MediciCore();
        vm.stopBroadcast();
    }

    function deployPeriphery() public {
        vm.startBroadcast();
        periphery = new Periphery();
        vm.stopBroadcast();
    }
}
