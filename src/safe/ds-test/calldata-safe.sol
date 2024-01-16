import {DSTest} from "ds-test/test.sol";

contract CalldataPropertiesSafe is DSTest {
    // read a symbolic index (less than length)
    function prove_read_symbolic_inbounds_safe(uint x, uint) public pure {
        require(x + 32 <= msg.data.length);
        bytes32 res;
        assembly { res := calldataload(x) }
        assert(0 <= uint(res) && uint(res) <= type(uint).max);
    }

    // read a symbolic index (past length)
    function prove_read_symbolic_past_length_safe(uint x, uint) public pure {
        require(x > msg.data.length);
        bytes32 res;
        assembly { res := calldataload(x) }
        assert(uint(res) == 0);
    }

    // calldata must be at least 4 bytes to hit this assert...
    function prove_calldata_min_size() public pure {
        assert(msg.data.length >= 4);
    }
}
