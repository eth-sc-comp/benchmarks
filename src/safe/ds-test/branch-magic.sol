// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSTest} from "ds-test/test.sol";

contract PostExample {
    bool live;

    modifier isLive() {
        require(live);
        _;
    }

    function setLive(bool _live) external {
        live = _live;
    }

    // https://github.com/foundry-rs/foundry/issues/2851
    function backdoor(uint256 x) external view isLive {
        uint256 number = 99;
        unchecked {
            uint256 z = x - 1;
            if (z == 6912213124124531) {
                number = 0;
            } else {
                number = 1;
            }
        }
        assert(number != 0);
    }
}

contract PostExampleTwoLiveTest is DSTest {
    PostExample public example;

    function setUp() public {
        example = new PostExample();
    }

    function proveBackdoor(bool isLive, uint256 x) public {
        example.setLive(isLive);
        example.backdoor(x);
    }
}
