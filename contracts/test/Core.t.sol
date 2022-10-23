pragma solidity 0.8.15;

pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
// import "forge-std/stdJson.sol";
import {BaseTest} from "../src/helpers/BaseTest.sol";
import "./LocalConfig.sol";
import "../src/core/MediciCore.sol";
import "../src/MediciStructs.sol";

contract CoreTest is BaseTest, MediciStructs {
    using stdJson for string;

    LocalConfig config;
    MediciCore core;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function setUp() public {
        vm.startBroadcast(deployerPrivateKey);
        config = new LocalConfig();

        // core = new MediciCore(
        //     config.
        //     config.getPersonhoodAddress()
        // );
        vm.stopBroadcast();
    }

    function testDeploy() public {
        assertTrue(true);
    }

    function testEncodeDecodeRequest() public {

        PayloadHeader memory header = PayloadHeader({
            payloadID: uint8(1),
            sender: msg.sender
        });

        bytes memory encoded = encodeBorrowRequestPayload(
                BorrowRequestPayload({
                    header: header,
                    borrowNormalizedAmount: 10000000,
                    borrowAddress: address(1),
                    apr: 1000000,
                    tenor: 524600000000
                })
            );

        BorrowRequestPayload memory decoded = decodeBorrowRequestPayload(encoded);
        assertEq(decoded.borrowNormalizedAmount, 10000000);
        assertEq(decoded.borrowAddress, address(1));
        assertEq(decoded.apr, 1000000);
        assertEq(decoded.tenor, 524600000000);
    }


    // function deployPeriphery() public {
    //     vm.startBroadcast(deployerPrivateKey);
    //     periphery = new Periphery();
    //     vm.stopBroadcast();
    // }
}
