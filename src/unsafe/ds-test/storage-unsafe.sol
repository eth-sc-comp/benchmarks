// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;
import "ds-test/test.sol";

contract C is DSTest {
    mapping (uint => mapping (uint => uint)) maps;

    function proveMappingAccess(uint x, uint y) public {
        maps[y][0] = x;
        maps[x][0] = y;
        assert(maps[y][0] == maps[x][0]);
    }
}
