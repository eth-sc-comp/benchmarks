// SPDX-License-Identifier: MIT

import {DSTest} from "ds-test/test.sol";

contract AssertFalse is DSTest {
    function prove_assert_false() public pure {
        assert(false);
    }
}
