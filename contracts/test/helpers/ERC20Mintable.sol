// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ERC20Mintable is ERC20 {
  address public admin;

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    admin = msg.sender;
  }

  function updateAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }

  function mint(address to, uint amount) external {
    require(msg.sender == admin, 'only admin');
    _mint(to, amount);
  }
}
