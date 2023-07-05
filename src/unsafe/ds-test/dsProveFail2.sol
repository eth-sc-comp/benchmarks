pragma solidity ^0.8.19;

import "ds-test/test.sol";
import "src/common/erc20.sol";

contract SolidityTest is DSTest {
    ERC20 token;

    function setUp() public {
        token = new ERC20("TOKEN", "TKN", 18);
    }

    function prove_transfer(uint supply, address usr, uint amt) public {
        token.mint(address(this), supply);

        uint prebal = token.balanceOf(usr);
        token.transfer(usr, amt);
        uint postbal = token.balanceOf(usr);

        uint expected = usr == address(this)
                        ? 0    // self transfer is a noop
                        : amt; // otherwise `amt` has been transfered to `usr`
        assert(expected == postbal - prebal);
    }
}

