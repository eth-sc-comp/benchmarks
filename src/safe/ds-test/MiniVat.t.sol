// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/common/MiniVat.sol";

contract MiniVatTest is Test {
    MiniVat public vat;

    function setUp() public {
        vat = new MiniVat();
        vat.init();
    }

    function proveInvariant() public {
        vat.frob(10 ** 18);
        vat.fold(-10 ** 27);
        vat.init();

        (uint Art, uint rate, uint debt) = vat.getValues();
        assertEq(debt, Art * rate);
    }
}
