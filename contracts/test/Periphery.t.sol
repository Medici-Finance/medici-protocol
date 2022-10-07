pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/console.sol";
// import "forge-std/stdJson.sol";
import "./LocalConfig.sol";
import "../src/core/MediciCore.sol";
import "./helpers/ERC20Mintable.SOL";
import "../src/periphery/Periphery.sol";
import {BaseTest} from "../src/helpers/BaseTest.sol";

contract PeripheryTest is BaseTest {
    using stdJson for string;

    LocalConfig config;
    MediciCore core;
    Periphery periphery;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address WORMHOLE_BC_MUMBAI = 0x0CBE91CF822c73C2315FB05100C2F714765d5c20;
    address WORMHOLE_BC_GOERLI = 0x706abc4E45D419950511e474C7B9Ed348A4a716c;
    address WORMHOLE_BC_FUJI = 0x7bbcE28e64B3F8b84d876Ab298393c38ad7aac4C;



    function setUp() public {

        ERC20Mintable gUSDC = new ERC20Mintable("gUSDC", "gUSDC", 6);

        periphery = new Periphery(
            WORMHOLE_BC_GOERLI,
            200,
            address(gUSDC)
        );

    }

    function testRegister() public {
        // periphery.registerCore();
    }
}
