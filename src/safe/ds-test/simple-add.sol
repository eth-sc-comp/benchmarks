// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;
import "ds-test/test.sol";

contract SimpleAdd is DSTest {
    function prove_add(uint x, uint y) public pure {
        unchecked {
            if (x + y < x) return; // no overflow
            assert(x + y >= x);
        }
    }
}
