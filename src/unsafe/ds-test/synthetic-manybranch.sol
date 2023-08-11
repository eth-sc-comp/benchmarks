// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";


function pathy(uint256 x) returns(bool) {
    uint256 acc = 1;

    // notice, all the values are primes. So the system has to figure
    // out the primal decomposition of the solution. Hence, there is a unique
    // solution (given that we cannot roll over due to low numbers)
    acc *= (x & 0xFF000000000000000000 > 0) ? uint256(  1) : uint256( 31);
    acc *= (x & 0x00FF0000000000000000 > 0) ? uint256(  3) : uint256( 37);
    acc *= (x & 0x0000FF00000000000000 > 0) ? uint256(  5) : uint256( 41);
    acc *= (x & 0x000000FF000000000000 > 0) ? uint256(  7) : uint256( 43);
    acc *= (x & 0x00000000FF0000000000 > 0) ? uint256( 11) : uint256( 47);
    acc *= (x & 0x0000000000FF00000000 > 0) ? uint256( 13) : uint256( 53);
    acc *= (x & 0x000000000000FF000000 > 0) ? uint256( 17) : uint256( 59);
    acc *= (x & 0x00000000000000FF0000 > 0) ? uint256( 19) : uint256( 61);
    acc *= (x & 0x0000000000000000FF00 > 0) ? uint256( 23) : uint256( 67);
    acc *= (x & 0x000000000000000000FF > 0) ? uint256( 29) : uint256( 71);

    // 31*3*5*7*47*13*59*19*67*71
    // = 10605495576585
    return acc != 10605495576585;
}

contract SyntheticManyBranch is Test {
    function prove_pAtHExPlOSion(uint256 x) external {
        assertTrue(pathy(x));
    }
}
