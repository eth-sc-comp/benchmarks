import {DSTest} from "ds-test/test.sol";

contract MemoryPropertiesUnsafe is DSTest {
    function prove_load_symbolic_index(uint idx) public {
        uint res;
        assembly { res := mload(idx) }
        assert(res == 0);
    }

    function prove_store_read_same_index_sym(uint idx, uint val) public {
        uint res;
        assembly {
            mstore(idx, val)
            res := mload(idx)
        }
        assert(res != val);
    }

    function prove_store_read_same_index_conc(uint val) public {
        uint res;
        assembly {
            mstore(1000, val)
            res := mload(1000)
        }
        assert(res != val);
    }

    function prove_read_non_aligned(uint val) public {
        uint res;
        assembly {
            mstore(0, val)
            mstore(32, 0)
            res := mload(16)
        }
        assert(res != (val << 128));
    }

    function prove_read_stacked_write(uint x, uint y) public {
        uint res;
        assembly {
            mstore(0, x)
            mstore(0, y)
            res := mload(0)
        }
        assert(res != y);
    }

    function prove_read_stacked_write_non_aligned(uint x, uint y) public {
        uint res;
        assembly {
            mstore(0, x)
            mstore(16, y)
            res := mload(0)
        }
        uint x_top = (x >> 128) << 128;
        uint y_bottom = (y << 128) >> 128;
        assert(res != x_top | y_bottom);
    }
}
