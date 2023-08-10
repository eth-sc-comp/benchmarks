// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";


function pathy(uint256 x) returns(bool) {
    int256 acc = 0;

    acc += (x & 0xFF > 0) ? int256(1) : int256(-1);
    acc += (x & 0xFF00 > 0) ? int256(-2) : int256(3);
    acc += (x & 0xFF0000 > 0) ? int256(5) : int256(-3);
    acc += (x & 0xFF000000 > 0) ? int256(7) : int256(-5);
    acc += (x & 0xFF00000000 > 0) ? int256(-7) : int256(11);
    acc += (x & 0xFF0000000000 > 0) ? int256(11) : int256(-7);
    acc += (x & 0xFF000000000000 > 0) ? int256(-13) : int256(17);
    acc += (x & 0xFF00000000000000 > 0) ? int256(17) : int256(-13);
    acc += (x & 0xFF0000000000000000 > 0) ? int256(-19) : int256(23);
    acc += (x & 0xFF000000000000000000 > 0) ? int256(23) : int256(-19);

    return acc > 0;
}

contract SyntheticManyBranch is Test {
    function prove_pAtHExPlOSion(uint256 x) external {
        assertTrue(pathy(x));
    }
}
