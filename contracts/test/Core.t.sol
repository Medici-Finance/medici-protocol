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
    address deployerAddress = vm.envAddress("ADDRESS");

    uint256 alicePrivateKey = vm.envUint("ALICE_PRIVATE_KEY");
    address aliceAddress = vm.envAddress("ALICE_ADDRESS");

    uint256 bobPrivateKey = vm.envUint("BOB_PRIVATE_KEY");
    address bobAddress = vm.envAddress("BOB_ADDRESS");

    address WORMHOLE_BC_MUMBAI = 0x0CBE91CF822c73C2315FB05100C2F714765d5c20;
    address WORMHOLE_BC_GOERLI = 0x706abc4E45D419950511e474C7B9Ed348A4a716c;
    address WORMHOLE_BC_FUJI = 0x7bbcE28e64B3F8b84d876Ab298393c38ad7aac4C;

    bytes32 GOERLI_PERI_BUFF= bytes32(uint256(uint160(0x342424f87c35943cfcea451a527964ab4BA1A6c7)));

    // alice loan - goerli
    // tenor - 60 days (in seconds)
    // max apr - 20e16
    // amount - 2000 USDC - e6
    bytes alice_loan = "0x01000000000100a5e9a1794c4583b8fb16bc6a9e22b4bca742de06e93b1f3c42618d8093b1d6680bf982995d5e2355ba67c12ab2617a3ed60000ece7bb999d9188bcf6dea2c7e10063549ad4000000000002000000000000000000000000775fbc57de090a99ba17aff3a71002890e3ec4270000000000000000c8019b342ea9775950b39b522a35c91970b46f5a91840000000000000000000000000000000000000000000000000000000077359400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f1a0000000000000000000000000000000000000000000000000002c68af0bb140000";

    function setUp() public {
        config = new LocalConfig();

        core = new MediciCore(
            WORMHOLE_BC_MUMBAI,
            200,
            config.getPersonhoodAddress()
        );
    }

    function testDeploy() public {
        core.registerChain(2, GOERLI_PERI_BUFF);
        console.logBytes32(GOERLI_PERI_BUFF);
    }

    function testHackenticate() internal {
        core.hackPerson(2, aliceAddress, "alice");


    }

    function initLoan() internal {

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
}
