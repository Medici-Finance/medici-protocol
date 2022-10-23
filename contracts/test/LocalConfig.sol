// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./InteractsWithWorldID.sol";
import "../src/MediciStructs.sol";

contract LocalConfig is InteractsWithWorldID {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address oracle;
        bytes32 jobId;
        uint256 chainlinkFee;
        address link;
        uint256 updateInterval;
        address priceFeed;
        uint64 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
    }

    Personhood public ph;

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[4] = getRinkebyEthConfig();
        chainIdToNetworkConfig[31_337] = getAnvilEthConfig();

        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];

        ph = new Personhood(worldID);
    }

    function getPersonhoodAddress() public view returns (address) {
        return address(ph);
    }

    function authBorrowerAccount(uint8 chainId, address account) external returns (bool) {
        registerIdentity(); // this simulates a World ID "verified" identity

        (uint256 nullifierHash, uint256[8] memory proof) = getProof(address(ph),_encodeWAddress(chainId, account));

        return ph.authenicate(chainId, account, getRoot(), nullifierHash, proof);
    }


    function toBytes(uint16 x) public returns (bytes memory c) {
        bytes2 b = bytes2(x);
        c = new bytes(2);
        for (uint256 i = 0; i < 2; i++) {
            c[i] = b[i];
        }
    }

    // helper util
    function _encodeWAddress(uint16 _chainId, address _address) public returns (bytes memory) {
        bytes memory addy = new bytes(32);
        assembly {
            mstore(add(addy, 32), _address)
        }
        return bytes.concat(toBytes(_chainId), addy);
    }


    function getRinkebyEthConfig() internal pure returns (NetworkConfig memory rinkebyNetworkConfig) {
        rinkebyNetworkConfig = NetworkConfig({
            oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8,
            jobId: "6b88e0402e5d415eb946e528b8e0c7ba",
            chainlinkFee: 1e17,
            link: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709,
            updateInterval: 60, // every minute
            priceFeed: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e, // ETH / USD
            subscriptionId: 0, // UPDATE ME!
            vrfCoordinator: 0x6168499c0cFfCaCD319c818142124B7A15E857ab,
            keyHash: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        });
    }

    function getGoerliConfig() internal pure returns (NetworkConfig memory goerliNetworkConfig) {
        goerliNetworkConfig = NetworkConfig({
            oracle: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            jobId: "6b88e0402e5d415eb946e528b8e0c7ba",
            chainlinkFee: 1e17,
            link: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            updateInterval: 60, // every minute
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // ETH / USD
            subscriptionId: 0, // UPDATE ME!
            vrfCoordinator: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            keyHash: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        });
    }

    function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            oracle: address(0), // This is a mock
            jobId: "6b88e0402e5d415eb946e528b8e0c7ba",
            chainlinkFee: 1e17,
            link: address(0), // This is a mock
            updateInterval: 60, // every minute
            priceFeed: address(0), // This is a mock
            subscriptionId: 0,
            vrfCoordinator: address(0), // This is a mock
            keyHash: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        });
    }
}
