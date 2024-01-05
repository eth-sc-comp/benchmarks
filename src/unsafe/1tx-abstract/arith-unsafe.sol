contract ArithmeticPropertiesUnchecked {
    function prove_add_mul_distributivity(uint x, uint y, uint z) public {
        unchecked {
            assert(x * (y + y) == (x * y) + (x * z));
        }
    }
    function prove_sub_comm(uint x, uint y) public {
        unchecked {
            assert(x - y == y - x);
        }
    }
    function prove_sub_assoc(uint x, uint y, uint z) public {
        unchecked {
            assert(x - (y - z) == (x - y) - z);
        }
    }
    function prove_div_distr(uint x, uint y, uint z) public {
        unchecked {
            assert(x / (y + z) == (x / y) + (x / z));
        }
    }
    function prove_div_assoc(uint x, uint y, uint z) public {
        unchecked {
            assert(x / (y / z) == (x / y) / z);
        }
    }
    function prove_sub_larger(int x, int y) public {
        require(x > y);
        unchecked {
            assert(y - x < 0);
        }
    }
}

contract ArithmeticPropertiesChecked {
    // TODO: whats up with hevm here????
    function prove_sub_comm(uint x, uint y) public {
        assert(x - y == y - x);
    }
    function prove_sub_assoc(uint x, uint y, uint z) public {
        assert(x - (y - z) == (x - y) - z);
    }
    function prove_div_distr(uint x, uint y, uint z) public {
        assert(x / (y + z) == (x / y) + (x / z));
    }
    function prove_div_assoc(uint x, uint y, uint z) public {
        assert(x / (y / z) == (x / y) / z);
    }
    function prove_sdiv_comm(int a, int b) public pure {
        require(a != 0 && b != 0, "One of the values is zero");
        assert(a / b == b / a);
    }
}
