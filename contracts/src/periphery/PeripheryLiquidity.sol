// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

abstract contract PeripheryVault {

    /// @dev Makes the actual deposit into the 'vault'
    /// @return Tuple (shares minted, amount underlying used)
    function _deposit() internal virtual returns (uint256, uint256);

    /// @dev Makes the actual withdraw from the 'vault'
    /// @return returns the amount produced
    function _withdraw(
        uint256,
        address,
        uint256
    ) internal virtual returns (uint256);

}
