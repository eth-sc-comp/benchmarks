// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

contract MyContractMulMod {
  function proveFun(uint8 a, uint8 b, uint8 c) external pure {
    require(a < 4);
    require(b < 4);
    require(c < 4);
    uint16 r1;
    uint16 r2;
    uint16 g2;
    assembly {
      r1 := mul(a,b)
      r2 := mod(r1, c)
      g2 := mulmod (a, b, c)
    }
    assert (r2 == g2);
  }
}
