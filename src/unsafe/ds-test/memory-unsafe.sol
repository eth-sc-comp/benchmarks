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

    function prove_read_non_aligned_conc_idx(uint val) public {
        uint res;
        assembly {
            mstore(0, val)
            mstore(32, 0)
            res := mload(16)
        }
        assert(res != (val << 128));
    }

    function prove_read_non_aligned_sym_idx(uint idx, uint val) public {
        uint res;
        uint next_word = idx + 32;
        uint half_word = idx + 16;
        assembly {
            mstore(idx, val)
            mstore(next_word, 0)
            res := mload(half_word)
        }
        assert(res != (val << 128));
    }

    function prove_read_stacked_write_conc_idx(uint x, uint y) public {
        uint res;
        assembly {
            mstore(0, x)
            mstore(0, y)
            res := mload(0)
        }
        assert(res != y);
    }

    function prove_read_stacked_write_sym_idx(uint idx, uint x, uint y) public {
        uint res;
        assembly {
            mstore(idx, x)
            mstore(idx, y)
            res := mload(0)
        }
        assert(res != y);
    }

    function prove_read_stacked_write_non_aligned_conc_idx(uint x, uint y) public {
        uint res;
        assembly {
            mstore(0, x)
            mstore(16, y)
            res := mload(0)
        }
        uint x_bits = (x >> 128) << 128;
        uint y_bits = (y >> 128);
        assert(res != x_bits | y_bits);
    }

    function prove_read_stacked_write_non_aligned_sym_idx(uint idx, uint x, uint y) public {
        uint res;
        uint half_word = idx + 16;
        assembly {
            mstore(idx, x)
            mstore(half_word, y)
            res := mload(0)
        }
        uint x_bits = (x >> 128) << 128;
        uint y_bits = (y >> 128);
        assert(res != x_bits | y_bits);
    }
}
