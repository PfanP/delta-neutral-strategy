// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '../../interfaces/oracle/IBaseOracle.sol';

contract UsingBaseOracle {
  IBaseOracle public immutable base; // Base oracle source

  constructor(IBaseOracle _base) public {
    base = _base;
  }
}
