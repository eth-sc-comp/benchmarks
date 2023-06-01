// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "src/utils.sol";

contract AssertFalse is Unsafe {
    function assert_false() public pure {
        assert(false);
    }
}
