// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

contract A {
  function proveF(uint x, uint y, uint z) public pure {
    bytes32 w; bytes32 u; bytes32 v;
    w = keccak256(abi.encode(x));
    u = keccak256(abi.encode(y));
    v = keccak256(abi.encode(z));
    if (w == u) assert(x==y);
    if (w == v) assert(x==z);
    if (u == v) assert(y==z);
  }
}
