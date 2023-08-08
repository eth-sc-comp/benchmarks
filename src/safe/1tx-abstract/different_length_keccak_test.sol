// SPDX-License-Identifier: AGPL-3.0-or-later
// submitted by @karmacoma on 3 Aug 2023

pragma solidity ^0.8.17;

contract MyKeccakTest {
    // we expect this to pass, there are no counterexamples
    function prove_keccakMeditations_mixedSizes1(uint128 x, uint256 y) external pure {
        assert(
            keccak256(abi.encodePacked(x)) !=
            keccak256(abi.encodePacked(y))
        );
    }
}
