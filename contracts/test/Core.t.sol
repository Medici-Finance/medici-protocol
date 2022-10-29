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

    bytes alice_loan = '\x01\x00\x00\x00\x00\x01\x00\xa5\xe9\xa1\x79\x4c\x45\x83\xb8\xfb\x16\xbc\x6a\x9e\x22\xb4\xbc\xa7\x42\xde\x06\xe9\x3b\x1f\x3c\x42\x61\x8d\x80\x93\xb1\xd6\x68\x0b\xf9\x82\x99\x5d\x5e\x23\x55\xba\x67\xc1\x2a\xb2\x61\x7a\x3e\xd6\x00\x00\xec\xe7\xbb\x99\x9d\x91\x88\xbc\xf6\xde\xa2\xc7\xe1\x00\x63\x54\x9a\xd4\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x77\x5f\xbc\x57\xde\x09\x0a\x99\xba\x17\xaf\xf3\xa7\x10\x02\x89\x0e\x3e\xc4\x27\x00\x00\x00\x00\x00\x00\x00\x00\xc8\x01\x9b\x34\x2e\xa9\x77\x59\x50\xb3\x9b\x52\x2a\x35\xc9\x19\x70\xb4\x6f\x5a\x91\x84\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x77\x35\x94\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x4f\x1a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xc6\x8a\xf0\xbb\x14\x00\x00';

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
