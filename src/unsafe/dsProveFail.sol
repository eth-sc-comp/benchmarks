pragma solidity ^0.8.19;

import "ds-test/test.sol";
import "../src/token.sol";
import "../src/math.sol";

contract Withdraw {
    receive() external payable {}

    function withdraw(uint password) public {
        require(password == 42, "Access denied!");
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract SolidityTest is DSTest, DSMath {
    DSToken token;
    Withdraw withdraw;

    function setUp() public {
        token = new DSToken("TKN");
        withdraw = new Withdraw();
    }

    function prove_transfer(uint supply, address usr, uint amt) public {
        token.mint(supply);

        uint prebal = token.balanceOf(usr);
        token.transfer(usr, amt);
        uint postbal = token.balanceOf(usr);

        uint expected = usr == address(this)
                        ? 0    // self transfer is a noop
                        : amt; // otherwise `amt` has been transfered to `usr`
        assert(expected == postbal - prebal);
    }

    function proveFail_withdraw(uint guess) public {
        payable(address(withdraw)).transfer(1 ether);
        uint preBalance = address(this).balance;
        withdraw.withdraw(guess);
        uint postBalance = address(this).balance;
        assert(preBalance + 1 ether == postBalance);
    }

    // allow sending eth to the test contract
    receive() external payable {}
}
