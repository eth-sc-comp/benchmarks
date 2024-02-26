import {DSTest} from "ds-test/test.sol";

contract UncheckedAddMulProperties is DSTest {
    function prove_add_commutative(uint x, uint y) public {
        unchecked {
            assert(x + y == y + x);
        }
    }
    function prove_add_assoc(uint x, uint y, uint z) public {
        unchecked {
            assert(x + (y + z) == (x + y) + z);
        }
    }
    function prove_mul_commutative(uint x, uint y) public {
        unchecked {
            assert(x * y == y * x);
        }
    }
    function prove_mul_assoc(uint x, uint y, uint z) public {
        unchecked {
            assert(x * (y * z) == (x * y) * z);
        }
    }
}

contract UncheckedDivProperties is DSTest {
    function prove_div_ident(uint x) public pure {
        unchecked {
            assert(x / 1 == x);
        }
    }
    function prove_div_mul_inverse_rough(uint x, uint y) public pure {
        unchecked {
            assert((x / y) * y <= x);
        }
    }
    function prove_zero_div(uint256 val) public pure {
      uint out;
      assembly {
        out := div(0, val)
      }
      assert(out == 0);

    }
    // TODO: does this actually hold if we have overflow?
    function prove_div_mul_inverse_precise(uint x, uint y) public {
        unchecked {
            assert(x == ((x / y) * y) + (x % y));
        }
    }
}

contract UnchekedSubProperties is DSTest {
    function prove_sub_inverse(uint x, uint y) public {
        unchecked {
            uint z = x + y;
            assert(z - y == x);
            assert(z - x == y);
        }
    }
    function prove_sub_ident(uint x) public {
        unchecked {
            assert(x - 0 == x);
        }
    }
    function prove_sub_neg(int x, int y) public {
        unchecked {
            assert(x - y == x + (- y));
        }
    }
}

contract CheckedAddMulProperties is DSTest {
    function prove_add_commutative(uint x, uint y) public {
        assert(x + y == y + x);
    }
    function prove_add_assoc(uint x, uint y, uint z) public {
        assert(x + (y + z) == (x + y) + z);
    }
    function prove_mul_commutative(uint x, uint y) public {
        assert(x * y == y * x);
    }
    function prove_mul_assoc(uint x, uint y, uint z) public {
        assert(x * (y * z) == (x * y) * z);
    }
    function prove_add_mul_distributivity(uint x, uint y, uint z) public {
        assert(x * (y + z) == (x * y) + (x * z));
    }
}

contract CheckedDivProperties is DSTest {
    function prove_div_ident(uint x) public {
        assert(x / 1 == x);
    }
    function prove_div_mul_inverse_rough(uint x, uint y) public {
        assert((x / y) * y <= x);
    }
    function prove_div_mul_inverse_precise(uint x, uint y) public {
        assert(x == ((x / y) * y) + (x % y));
    }
}

contract CheckedSubProperties is DSTest {
    function prove_sub_inverse(uint x, uint y) public {
        uint z = x + y;
        assert(z - y == x);
        assert(z - x == y);
    }
    function prove_sub_ident(uint x) public {
        assert(x - 0 == x);
    }
    function prove_sub_neg(int x, int y) public {
        assert(x - y == x + (- y));
    }
    function prove_sub_larger(int x, int y) public {
        require(x > y);
        assert(y - x < 0);
    }
}

contract ModProperties is DSTest {
    function prove_mod_range(uint x, uint y) public {
        uint res = x % y;
        assert(0 <= res);
        assert(res <= y - 1);
    }
    function prove_mod_periodicity(uint x, uint y, uint z) public {
        assert(x % y == (x + (z * y)) % y);
    }
    function prove_mod_add_comm(uint x, uint y, uint z) public {
        assert((x + z) % y == ((x % y) + (z % y)) % y);
    }
    function prove_mod_mul_comm(uint x, uint y, uint z) public {
        assert((x * z) % y == ((x % y) * (z % y)) % y);
    }
    function prove_mod_add_distr(uint x, uint y, uint z) public {
        assert((x + z) % y == ((x % y) + (z % y)) % y);
    }
    function prove_mod_mul_distr(uint x, uint y, uint z) public {
        assert((x * z) % y == ((x % y) * (z % y)) % y);
    }
}

contract AddModProperties is DSTest {
    function prove_addmod_range(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint result = addmod(a, b, N);
        assert(result >= 0 && result < N);
    }

    function prove_addmod_comm(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(addmod(a, b, N) == addmod(b, a, N));
    }

    function prove_addmod_assoc(uint a, uint b, uint c, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(addmod(a, addmod(b, c, N), N) == addmod(addmod(a, b, N), c, N));
    }

    function prove_addmod_identity(uint a, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(addmod(a, 0, N) == a % N);
    }

    function prove_addmod_inverse(uint a, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint inverse = N - (a % N);
        assert(addmod(a, inverse, N) == 0);
    }

    function prove_addmod_periodicity(uint a, uint b, uint k, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(addmod(a, b, N) == addmod(a, b + k * N, N));
    }

    function prove_addmod_nonzero(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint result = addmod(a, b, N);
        assert(result >= 0);
    }

    function prove_addmod_equiv(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint result = addmod(a, b, N);
        assert(result == (a + b) % N);
    }

    function prove_addmod_no_overflow(uint8 a, uint8 b, uint8 c) external pure {
        require(a < 4);
        require(b < 4);
        require(c < 4);
        uint16 r1;
        uint16 r2;
        uint16 g2;
        assembly {
            r1 := add(a,b)
            r2 := mod(r1, c)
            g2 := addmod (a, b, c)
        }
        assert (r2 == g2);
    }
}

contract MulModProperties is DSTest {
    function prove_mulmod_range(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint result = mulmod(a, b, N);
        assert(result >= 0 && result < N);
    }

    // Asserts commutativity of mulmod
    function prove_mulmod_commutivity(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(mulmod(a, b, N) == mulmod(b, a, N));
    }

    function prove_mulmod_distributivity(uint a, uint b, uint c, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(mulmod(a, addmod(b, c, N), N) == addmod(mulmod(a, b, N), mulmod(a, c, N), N));
    }

    function prove_mulmod_identity(uint a, uint N) public pure {
        require(N != 0, "N should be non-zero");
        assert(mulmod(a, 1, N) == a % N);
    }

    function prove_mulmod_nonzero(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint result = mulmod(a, b, N);
        assert(result >= 0);
    }

    function prove_mulmod_equiv(uint a, uint b, uint N) public pure {
        require(N != 0, "N should be non-zero");
        uint result = mulmod(a, b, N);
        assert(result == (a * b) % N);
    }

    function prove_mulmod_no_overflow(uint8 a, uint8 b, uint8 c) external pure {
        require(a < 4);
        require(b < 4);
        require(c < 4);
        uint16 r1;
        uint16 r2;
        uint16 g2;
        assembly {
            r1 := mul(a,b)
            r2 := mod(r1, c)
            g2 := mulmod (a, b, c)
        }
        assert (r2 == g2);
    }
}


contract SignedDivisionProperties is DSTest {
    // helpers
    function sdiv(int a, int b) internal pure returns (int res) {
        assembly { res := sdiv(a, b) }
    }

    // properties
    function prove_divide_anything_by_zero(int a) public {
        assert(sdiv(a,0) == 0);
    }

    function prove_divide_zero_by_anything(int a) public {
        int result = sdiv(0, a);
        assert(result == 0);
    }

    function prove_divide_positive_by_positive(int a, int b) public {
        require(a > 0);
        require(b > 0);
        int result = sdiv(a, b);
        assert(result >= 0);
    }

    function prove_divide_positive_by_negative(int a, int b) public {
        require(a > 0);
        require(b < 0);
        int result = sdiv(a, b);
        assert(result <= 0);
    }

    function prove_divide_negative_by_positive(int a, int b) public {
        require(a < 0);
        require(b > 0);
        int result = sdiv(a, b);
        assert(result <= 0);
    }

    function prove_divide_negative_by_negative(int a, int b) public {
        require(a < 0);
        require(b < 0);
        int result = sdiv(a, b);
        assert(result >= 0);
    }
}

contract SignedModuloProperties is DSTest {
    // helpers
    function smod(int a, int b) internal pure returns (int res) {
        assembly { res := smod(a, b) }
    }
    function abs(int x) internal pure returns (int) {
        return x >= 0 ? x : -x;
    }


    // properties
    function prove_smod_by_zero(int a) public pure {
        int res = smod(a,0);
        assert(res == 0);
    }
    function prove_range(int a, int b) public pure {
        require(b != 0, "Modulo by zero is not allowed");
        int result = smod(a, b);
        assert(abs(result) < abs(b));
    }
    function prove_smod_non_comm(int a, int b) public pure {
        require(b != 0 && a != 0, "One of the values is zero");
        int resultA = smod(a, b);
        int resultB = smod(b, a);
        assert(resultA != resultB || abs(a) == abs(b));
    }
    function prove_smod_preserves_sign(int a, int b) public pure {
        require(b != 0, "Modulo by zero is not allowed");
        int result = smod(a, b);
        assert((a > 0 && result >= 0) || (a < 0 && result <= 0));
    }
}

contract SignExtendProperties is DSTest {
    function signExtend(uint8 byteNumber, int256 value) private pure returns (int256 res) {
        assembly {
            res := signextend(byteNumber, value)
        }
    }

    function prove_preservation_of_sign(int8 a) public pure {
        int256 extended = signExtend(0, a); // extend from 8-bit to 256-bit
        assert((a < 0 && extended < 0) || (a >= 0 && extended >= 0));
    }

    function prove_preservation_of_value_for_non_negative(int8 a) public pure {
        require(a >= 0);
        int256 extended = signExtend(0, a); // extend from 8-bit to 256-bit
        assert(extended == a);
    }

    function prove_correct_extension_for_negative_numbers(int8 a) public pure {
        require(a < 0);
        int256 extended = signExtend(0, a); // extend from 8-bit to 256-bit
        int256 reExtended = signExtend(0, extended); // extend again
        assert(extended == reExtended); // should remain the same after re-extension
    }
}
