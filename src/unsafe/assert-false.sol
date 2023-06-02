// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

contract AssertFalse {
    function assert_false() public pure {
        assert(false);
    }
}
