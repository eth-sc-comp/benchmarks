// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;
import "ds-test/test.sol";

contract MyContractDiv is DSTest {
  function prove_fun(uint256 val) external pure {
    uint out;
    assembly {
      out := div(0, val)
    }
    assert(out == 0);

  }
}
