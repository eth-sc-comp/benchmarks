// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PostExample.sol";

contract PostExampleTest is Test {
    PostExample public example;

    function setUp() public {
        example = new PostExample();
    }

    function testBackdoor(uint256 x) public view {
        example.backdoor(x);
    }

    function proveBackdoor(uint256 x) public view {
        example.backdoor(x);
    }

    /*
    function testBackdoor_k(uint256 x) public {
        setUp();
        example.backdoor(x);
    }
    */
}
