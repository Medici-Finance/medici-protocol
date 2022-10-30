// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "./IERC20Permit.sol";

interface ITranche is IERC20Permit {
    function supply(
        uint256 amount_,
        uint256 loanId,
        uint16 chainID,
        address borrower
    ) external;

    function prefundedSupply(
        uint256 loanId,
        uint16 chainID,
        address borrower
    ) external;

}
