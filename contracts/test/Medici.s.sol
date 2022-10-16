pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/console.sol";
// import "forge-std/stdJson.sol";
import "./LocalConfig.sol";
import "../src/core/MediciCore.sol";
import "./helpers/ERC20Mintable.sol";
import "../src/helpers/MToken.sol";
import "../src/periphery/Periphery.sol";

contract Medici is Script {
    using stdJson for string;

    LocalConfig config;
    MediciCore core;
    Periphery periphery;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.envAddress("ADDRESS");

    uint256 alicePrivateKey = vm.envUint("ALICE_PRIVATE_KEY");
    address aliceAddress = vm.envAddress("ALICE_ADDRESS");

    uint256 bobPrivateKey = vm.envUint("BOB_PRIVATE_KEY");
    address bobAddress = vm.envAddress("BOB_ADDRESS");

    address WORMHOLE_BC_MUMBAI = 0x0CBE91CF822c73C2315FB05100C2F714765d5c20;
    address WORMHOLE_BC_GOERLI = 0x706abc4E45D419950511e474C7B9Ed348A4a716c;
    address WORMHOLE_BC_FUJI = 0x7bbcE28e64B3F8b84d876Ab298393c38ad7aac4C;


    function run() public {
        deployCore();
    }

    function deployCore() public {
        vm.startBroadcast(deployerPrivateKey);
        config = new LocalConfig();


        core = new MediciCore(
            WORMHOLE_BC_MUMBAI,
            200,
            config.getPersonhoodAddress()
        );
        core.setNonce();
        vm.stopBroadcast();
    }


    function deployPeripheryGeorli() public {
        vm.startBroadcast(deployerPrivateKey);

        ERC20Mintable gUSDC = new ERC20Mintable("gUSDC", "gUSDC", 6);
        gUSDC.mint(aliceAddress, 1000_000e6);
        gUSDC.mint(bobAddress, 1000_000e6);

        periphery = new Periphery(
            WORMHOLE_BC_GOERLI,
            200,
            address(gUSDC)
        );
        MToken mDebt = new MToken(
            periphery,
            address(gUSDC),
            6,
            "mDebt",
            "MICI"
        );
        periphery.setMToken(address(mDebt));
        vm.stopBroadcast();
    }

    function deployPeripheryFuji() public {
        vm.startBroadcast(deployerPrivateKey);

        ERC20Mintable fUSDC = new ERC20Mintable("fUSDC", "fUSDC", 6);
        fUSDC.mint(aliceAddress, 1000_000e6);
        fUSDC.mint(bobAddress, 1000_000e6);

        periphery = new Periphery(
            WORMHOLE_BC_FUJI,
            200,
            address(fUSDC)
        );
        MToken mDebt = new MToken(
            periphery,
            address(fUSDC),
            6,
            "mDebt",
            "MICI"
        );
        periphery.setMToken(address(mDebt));
        vm.stopBroadcast();
    }
}
