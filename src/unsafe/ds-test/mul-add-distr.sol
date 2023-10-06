// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;
import "ds-test/test.sol";

contract C is DSTest {
    function prove_easy(uint v) public pure {
        if (v != 100) return;
        assert(v == 100);
    }

    function prove_add(uint x, uint y) public pure {
        unchecked {
            if (x + y < x) return; // no overflow
            assert(x + y >= x);
        }
    }

    function prove_complicated(uint x, uint y, uint z) public pure {
        if ((x * y / z) * (x / y) / (x * y) == (x * x * x * y * z / x * z * y)) {
            assert(false);
        } else {
            assert(true);
        }
    }

    function prove_multi(uint x) public pure {
        if (x == 3) {
            assert(false);
        } else if (x == 9) {
            assert(false);
        } else if (x == 1023423194871904872390487213) {
            assert(false);
        } else {
            assert(true);
        }
    }

    function prove_distributivity(uint120 x, uint120 y, uint120 z) public pure {
        assert(x + (y * z) == (x + y) * (x + z));
    }

    function prove_add2(uint x, uint y) public pure {
        assert(x + y >= x);
    }
}
