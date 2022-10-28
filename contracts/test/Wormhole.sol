pragma solidity 0.8.15;

pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
// import "forge-std/stdJson.sol";
import {BaseTest} from "../src/helpers/BaseTest.sol";

import "../src/MediciStructs.sol";

contract CoreTest is BaseTest, MediciStructs {
    using stdJson for string;


    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.envAddress("ADDRESS");

    uint256 alicePrivateKey = vm.envUint("ALICE_PRIVATE_KEY");
    address aliceAddress = vm.envAddress("ALICE_ADDRESS");

    uint256 bobPrivateKey = vm.envUint("BOB_PRIVATE_KEY");
    address bobAddress = vm.envAddress("BOB_ADDRESS");




    function setUp() public {}

    function testEncodeDecodeRequest() public {

        PayloadHeader memory header = PayloadHeader({
            payloadID: uint8(1),
            sender: aliceAddress
        });

        bytes memory encoded = encodeBorrowRequestPayload(
                BorrowRequestPayload({
                    header: header,
                    borrowNormalizedAmount: 10000000,
                    borrowAddress: address(1),
                    apr: 200000000000000000,
                    tenor: 5184000
                })
            );

        console.log("Msg: ");
        console.logBytes(encoded);

        BorrowRequestPayload memory decoded = decodeBorrowRequestPayload(encoded);
        assertEq(decoded.header.payloadID, 1);
        assertEq(decoded.header.sender, aliceAddress);
        assertEq(decoded.borrowNormalizedAmount, 10000000);
        assertEq(decoded.borrowAddress, address(1));
        assertEq(decoded.apr, 200000000000000000);
        assertEq(decoded.tenor, 5184000);
    }
}
