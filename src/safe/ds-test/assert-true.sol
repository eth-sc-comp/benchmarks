// SPDX-License-Identifier: MIT

import {DSTest} from "ds-test/test.sol";

contract AssertTrue is DSTest {
    function prove_assert_true() public pure {
        assert(true);
    }
}
