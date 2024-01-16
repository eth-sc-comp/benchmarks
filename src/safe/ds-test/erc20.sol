import "ds-test/test.sol";
import "src/common/erc20.sol";

contract SolidityTestPass is DSTest {
    ERC20 token;

    function setUp() public {
        token = new ERC20("tkn", "tkn", 18);
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

    function prove_burn(uint supply, uint amt) public {
        if (amt > supply) return; // no undeflow

        token.mint(address(this), supply);
        token.burn(address(this), amt);

        assert(supply - amt == token.totalSupply());
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
