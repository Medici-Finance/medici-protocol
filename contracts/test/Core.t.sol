pragma solidity 0.8.15;

pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
// import "forge-std/stdJson.sol";
import {BaseTest} from "../src/helpers/BaseTest.sol";
import "./LocalConfig.sol";
import "../src/core/MediciCore.sol";
import "../src/periphery/Periphery.sol";

contract CoreTest is BaseTest {
    using stdJson for string;

    LocalConfig config;
    MediciCore core;
    Periphery periphery;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function setUp() public {
        vm.startBroadcast(deployerPrivateKey);
        config = new LocalConfig();
        string memory Xconfig = vm.readFile("../xdapp.config.json");
        string memory network = stdJson.readString(Xconfig, "key");
        console.log("network: ", network);

        // core = new MediciCore(
        //     config.
        //     config.getPersonhoodAddress()
        // );
        vm.stopBroadcast();
    }

    function testDeploy() public {
        assertTrue(true);
    }

    // function deployPeriphery() public {
    //     vm.startBroadcast(deployerPrivateKey);
    //     periphery = new Periphery();
    //     vm.stopBroadcast();
    // }
}
