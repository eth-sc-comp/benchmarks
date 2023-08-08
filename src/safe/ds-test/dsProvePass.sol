pragma solidity ^0.8.19;

import "ds-test/test.sol";
import "src/common/erc20.sol";

contract ConstructorArg {
    address immutable public a;
    constructor(address _a) {
        a = _a;
    }
}

contract SolidityTestPass is DSTest {
    ERC20 token;

    function setUp() public {
        token = new ERC20("Token", "TKN", 18);
    }

    function prove_balance(address usr, uint amt) public {
        assert(0 == token.balanceOf(usr));
        token.mint(usr, amt);
        assert(amt == token.balanceOf(usr));
    }

    function prove_supply(uint supply) public {
        token.mint(address(this), supply);
        uint actual = token.totalSupply();
        assert(supply == actual);
    }

    function prove_constrArgs(address b) public {
        ConstructorArg c = new ConstructorArg(b);
        assert(b == c.a());
    }

    function prove_transfer(uint supply, address usr, uint amt) public {
        if (amt > supply) return; // no underflow

        token.mint(address(this), supply);

        uint prebal = token.balanceOf(usr);
        token.transfer(usr, amt);
        uint postbal = token.balanceOf(usr);

        uint expected = usr == address(this)
                        ? 0    // self transfer is a noop
                        : amt; // otherwise `amt` has been transfered to `usr`
        assert(expected == postbal - prebal);
    }

    function prove_burn(uint supply, uint amt) public {
        if (amt > supply) return; // no undeflow

        token.mint(address(this), supply);
        token.burn(address(this), amt);

        assert(supply - amt == token.totalSupply());
    }
}
