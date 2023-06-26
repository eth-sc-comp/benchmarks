// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MiniVat.sol";

contract MiniVatTest is Test {
    MiniVat public vat;

    function setUp() public {
        vat = new MiniVat();
        vat.init();
    }

    function testInvariant() public {
        vat.frob(10 ** 18);
        vat.fold(-10 ** 27);
        vat.init();

        (uint Art, uint rate, uint debt) = vat.getValues();
        assertEq(debt, Art * rate);
    }

    function proveInvariant() public {
        vat.frob(10 ** 18);
        vat.fold(-10 ** 27);
        vat.init();

        (uint Art, uint rate, uint debt) = vat.getValues();
        assertEq(debt, Art * rate);
    }

    /*
    function testInvariant_k() public {
        setUp();

        vat.frob(10 ** 18);
        vat.fold(-10 ** 27);
        vat.init();

        (uint Art, uint rate, uint debt) = vat.getValues();
        assertEq(debt, Art * rate);
    }

    function testCounterexample() public {
        vat.counterexample();
    }

    function proveCounterexample() public {
        vat.counterexample();
    }
    */
}
