// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;
pragma abicoder v2;

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    Lend,
    Borrow,
    Settle,
    Swap,
    Redeem
}

/****** Calldata objects ******/

/// @notice Defines a batch lending action
struct BatchLend {
    address currencyAddress;
    bool depositUnderlying;
    bytes32[] trades;
}


