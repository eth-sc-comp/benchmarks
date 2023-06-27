// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

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
