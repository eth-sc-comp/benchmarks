// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Foo} from "../src/Foo.sol";

contract FooTest is Test {
    Foo internal a;

    function setUp() public {
        a = new Foo();
    }

    /// @dev Attempts to find a combination of `x` and `y` that will cause
    /// this test to revert. In order to do so, both `x` and `y` should
    /// be equal to `0x69`.
    function testFuzz_cracked(uint256 x, uint256 y) public {
        a.foo(x);
        a.bar(y);
        a.revertIfCracked();
    }

    function proveFuzz_cracked(uint256 x, uint256 y) public {
        a.foo(x);
        a.bar(y);
        a.revertIfCracked();
    }

    /*
    function testFuzz_cracked_k(uint256 x, uint256 y) public {
        setUp();

        a.foo(x);
        a.bar(y);
        a.revertIfCracked();
    }
    */
}
