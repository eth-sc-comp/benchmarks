// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";


function pathy(uint256 x) returns(bool) {
    int256 acc = 1;

    // notice, all the values are primes. So the system has to figure
    // out the primal decomposition of the solution. Hence, there is a unique
    // solution (given that we cannot roll over due to low numbers)
    acc *= (x & 0xFF > 0)                   ? int256(  1) : int256( 31);
    acc *= (x & 0x00FF > 0)                 ? int256(  3) : int256( 37);
    acc *= (x & 0x0000FF > 0)               ? int256(  5) : int256( 41);
    acc *= (x & 0x000000FF > 0)             ? int256(  7) : int256( 43);
    acc *= (x & 0x00000000FF > 0)           ? int256( 11) : int256( 47);
    acc *= (x & 0x0000000000FF > 0)         ? int256( 13) : int256( 53);
    acc *= (x & 0x000000000000FF > 0)       ? int256( 17) : int256( 59);
    acc *= (x & 0x00000000000000FF > 0)     ? int256( 19) : int256( 61);
    acc *= (x & 0x0000000000000000FF > 0)   ? int256( 23) : int256( 67);
    acc *= (x & 0x000000000000000000FF > 0) ? int256( 29) : int256( 71);

    // 31*3*5*7*47*13*59*19*67*71
    // = 10605495576585
    return acc != 10605495576585;
}

contract SyntheticManyBranch is Test {
    function prove_pAtHExPlOSion(uint256 x) external {
        assertTrue(pathy(x));
    }
}
