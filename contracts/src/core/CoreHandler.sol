// periphery/Periphery.sol
// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "../MediciStructs.sol";
import "./MediciCore.sol";

contract CoreHandler {
    MediciCore public core;

    mapping (address => bool) public whitelistBorrowAssets;

    constructor(address coreAddress) {
        core = MediciCore(coreAddress);
    }


    function request(
        address borrowAssetAddress,
        uint256 loanAmt,
        uint256 maxApr,
        uint256 tenor
    ) external returns (bool) {
        require(tenor <= maxTenor(), "Loan tenor too long");
        require(loanAmt > 0, "Loan amount must be greater than 0");
        require(whitelistBorrowAssets[borrowAssetAddress], "Borrow asset not whitelisted");

        bytes memory payload = encodeBorrowRequestPayload(
            BorrowRequestPayload({
                header: header,
                borrowNormalizedAmount: loanAmt,
                borrowAddress: borrowAssetAddress,
                apr: apr,
                tenor: tenor
            })
        );

        return core.request(payload, false);
    }

    function checkWhitelistBorrowAsset(address borrowAssetAddress) external view returns (bool) {
        return whitelistBorrowAssets[borrowAssetAddress];
    }
}
