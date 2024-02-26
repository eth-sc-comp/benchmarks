pragma solidity ^0.8.19;

import "ds-test/test.sol";

contract ConstructorArg {
    address immutable public a;
    constructor(address _a) {
        a = _a;
    }
}

contract ConstructorPropertiesSafe is DSTest {
    function prove_constrArgs(address b) public {
        ConstructorArg c = new ConstructorArg(b);
        assert(b == c.a());
    }
}
