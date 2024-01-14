// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {DSTest} from "ds-test/test.sol";

contract XorMagic {
    uint256 internal constant MAGIC = 0x69;

    uint256 internal flagA = 0;
    uint256 internal flagB = 0;

    function foo(uint256 x) external {
        assembly {
            if iszero(xor(x, MAGIC)) {
                sstore(flagA.slot, 0x01)
            }
        }
    }

    function bar(uint256 y) external {
        assembly {
            if iszero(xor(y, MAGIC)) {
                sstore(flagB.slot, 0x01)
            }
        }
    }

    function revertIfCracked() external view {
        bool res = true;
        assembly {
            if and(sload(flagA.slot), sload(flagB.slot)) {
                res := false
            }
        }
        assert(res);
    }
}

contract XorMagicTest is DSTest {
    XorMagic internal a;

    function setUp() public {
        a = new XorMagic();
    }

    /// @dev Attempts to find a combination of `x` and `y` that will cause
    /// this test to revert. In order to do so, both `x` and `y` should
    /// be equal to `0x69`.
    function proveFuzz_cracked(uint256 x, uint256 y) public {
        a.foo(x);
        a.bar(y);
        a.revertIfCracked();
    }
}
