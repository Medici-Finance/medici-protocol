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
    // using stdJson for string;

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
    // tenor - 5184000 (60 days)
    // max apr - 200000000000000000 (20e16)
    // amount - 2000000000 (2000e6)

    bytes alice_loan = hex"019b342ea9775950b39b522a35c91970b46f5a91840000000000000000000000000000000000000000000000000000000077359400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f1a0000000000000000000000000000000000000000000000000002c68af0bb140000";

    // bytes alice_loan = 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef;

    // bytes alice_loan = new bytes(32);
    // assembly {
    //     mstore(add(b, 32), 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef)
    // }

    function setUp() public {
        config = new LocalConfig();

        core = new MediciCore(
            WORMHOLE_BC_MUMBAI,
            200,
            config.getPersonhoodAddress()
        );
    }

    function testExample() internal {
        assertTrue(true);
    }

    function testDeploy() internal {
        core.registerChain(2, GOERLI_PERI_BUFF);
        console.logBytes32(GOERLI_PERI_BUFF);
    }

    function testHackenticate() internal {
        core.hackPerson(2, aliceAddress, "alice");


    }

    function testSanity_loanRequest() public {
        // console.log(alice_loan.length);
        console.logBytes(alice_loan);
        core.initLoan(alice_loan);

    }

    function initLoan() internal {

    }


}
