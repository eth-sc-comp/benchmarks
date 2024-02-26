import {DSTest} from "ds-test/test.sol";

contract ArithmeticPropertiesUncheckedUnsafe is DSTest {
    function prove_add_mul_distributivity(uint x, uint y, uint z) public pure {
        unchecked {
            assert(x * (y + y) == (x * y) + (x * z));
        }
    }
    function prove_sub_comm(uint x, uint y) public pure {
        unchecked {
            assert(x - y == y - x);
        }
    }
    function prove_sub_assoc(uint x, uint y, uint z) public pure {
        unchecked {
            assert(x - (y - z) == (x - y) - z);
        }
    }
    function prove_div_distr(uint x, uint y, uint z) public pure {
        unchecked {
            assert(x / (y + z) == (x / y) + (x / z));
        }
    }
    function prove_div_assoc(uint x, uint y, uint z) public pure {
        unchecked {
            assert(x / (y / z) == (x / y) / z);
        }
    }
    function prove_sub_larger(int x, int y) public pure {
        require(x > y);
        unchecked {
            assert(y - x < 0);
        }
    }

    function prove_add2(uint x, uint y) public pure {
        unchecked {
            assert(x + y >= x);
        }
    }
}

contract ArithmeticPropertiesCheckedUnsafe is DSTest {
    function prove_sub_assoc(uint x, uint y, uint z) public pure {
        assert(x - (y - z) == (x - y) - z);
    }
    function prove_div_distr(uint x, uint y, uint z) public pure {
        assert(x / (y + z) == (x / y) + (x / z));
    }
    function prove_div_assoc(uint x, uint y, uint z) public pure {
        assert(x / (y / z) == (x / y) / z);
    }
    function prove_sdiv_comm(int a, int b) public pure {
        require(a != 0 && b != 0, "One of the values is zero");
        assert(a / b == b / a);
    }
    function prove_distributivity(uint120 x, uint120 y, uint120 z) public pure {
        assert(x + (y * z) == (x + y) * (x + z));
    }
    function prove_complicated(uint x, uint y, uint z) public pure {
        assert((((x * y) / z) * x) / (x * y * z) == (((x * y) + z) / x) * (y / z));
    }
}
