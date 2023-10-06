// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/common/PostExample_2tx.sol";

contract PostExampleTwoLiveTest is Test {
    PostExample public example;

    function setUp() public {
        example = new PostExample();
        // `setLive` is called in the test itself
        // example.setLive(true);
    }

    function testBackdoor(bool isLive, uint256 x) public {
        example.setLive(isLive);
        example.backdoor(x);
    }

    function proveBackdoor(bool isLive, uint256 x) public {
        example.setLive(isLive);
        example.backdoor(x);
    }
}
