// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {ERC20Permit} from "../lib/ERC20Permit.sol";
import {ITranche} from "../interfaces/ITranche.sol";
import {Periphery} from "../periphery/Periphery.sol";

contract Tranche is ERC20Permit, ITranche {
    Periphery public immutable periphery;
    uint16 public immutable wormholeChainId;
    IERC20 public immutable override underlying;
    uint8 internal immutable override _underlyingDecimals;


    // The outstanding amount of underlying which
    // can be redeemed from the contract from Principal Tokens
    // NOTE - we use smaller sizes to match with Element's Tranche contract
    uint128 public valueSupplied;
    // The timestamp when tokens can be redeemed.
    uint256 public immutable override unlockTimestamp;


    /// @notice Constructs this contract
    function supply(
        uint256 amount_,
        uint256 loanId,
        uint16 chainID,
        address borrower
    ) external override returns (uint256) {
        // Transfer the underlying to the periphery contract holding liquidity for every chain
        underlying.transferFrom(msg.sender, address(periphery), amount_);
        // Now that we have funded the supply we can call
        // the prefunded supply
        // supply callback
        return  periphery.enrichLoanCallback(
            amount_,
            loanId,
            chainID,
            borrower
        );

    }

    function prefundedSupply(
        uint256 loanId,
        uint16 chainID,
        address borrower
        bytes calldata xData
    ) external override returns (uint256) {

        // We check that this it is possible to deposit
        require(block.timestamp < unlockTimestamp, "expired");

        // TODO: check wormhole loan recipt on callback
        (uint256 shares, ) = periphery.checkLoanReceiptCallback(xData);

        _mint(msg.sender, shares);

        return shares;
    }
}
