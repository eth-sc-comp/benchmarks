// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

contract C {
    mapping (uint => mapping (uint => uint)) maps;

    function proveF(uint x, uint y) public view {
        assert(maps[y][0] == maps[x][0]);
    }
}
