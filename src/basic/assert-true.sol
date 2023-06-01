// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "src/utils.sol";

contract AssertTrue is Safe {
    function assert_true() public pure {
        assert(true);
    }
}
