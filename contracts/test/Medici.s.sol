// pragma solidity 0.8.15;
// pragma experimental ABIEncoderV2;

// import "forge-std/Script.sol";
// import "./LocalConfig.sol";
// import "../src/core/MediciCore.sol";
// import "../src/periphery/Periphery.sol";

// contract Medici is Script {
//     LocalConfig config;
//     MediciCore core;
//     Periphery periphery;
//     // string Xconfig = vm.readFile("../xdapp.config.json");
//     uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");


//     function run() public {
//         deployCore();
//     }

//     function deployCore() public {
//         vm.startBroadcast(deployerPrivateKey);
//         config = new LocalConfig();
//         core = new MediciCore(config.getPersonhoodAddress());
//         vm.stopBroadcast();
//     }

//     function deployPeriphery() public {
//         vm.startBroadcast(deployerPrivateKey);
//         periphery = new Periphery();
//         vm.stopBroadcast();
//     }
// }
