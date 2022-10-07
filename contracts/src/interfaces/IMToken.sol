pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMToken is IERC20 {
    event Initialized(
        address indexed underlyingAsset, address indexed core, uint8 indexed decimals, string name, string symbol
    );
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` mTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address user, uint256 amount, uint256 index) external returns (bool);
}
