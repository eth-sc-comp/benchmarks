import {DSTest} from "ds-test/test.sol";

contract CalldataPropertiesUnsafe is DSTest {
    // read a symbolic index (less than length)
    function prove_read_symbolic_inbounds_unsafe(uint x, uint) public pure {
        require(x + 32 <= msg.data.length);
        bytes32 res;
        assembly { res := calldataload(x) }
        assert(uint(res) == x);
    }

    // read a symbolic index (past length)
    function prove_read_symbolic_past_length_unsafe(uint x, uint) public pure {
        require(x > msg.data.length);
        bytes32 res;
        assembly { res := calldataload(x) }
        assert(uint(res) != 0);
    }

    // calldata can be any length
    function prove_calldata_abstract_size() public pure {
        assert(msg.data.length == 4);
    }
}
