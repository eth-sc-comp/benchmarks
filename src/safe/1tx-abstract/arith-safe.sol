contract UncheckedAddMulProperties {
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

contract UncheckedDivProperties {
    function prove_div_ident(uint x) public {
        unchecked {
            assert(x / 1 == x);
        }
    }
    function prove_div_mul_inverse_rough(uint x, uint y) public {
        unchecked {
            assert((x / y) * y <= x);
        }
    }
    // TODO: does this actually hold if we have overflow?
    function prove_div_mul_inverse_precise(uint x, uint y) public {
        unchecked {
            assert(x == ((x / y) * y) + (x % y));
        }
    }
}

contract UnchekedSubProperties {
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

contract CheckedAddMulProperties {
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
        assert(x * (y + y) == (x * y) + (x * z));
    }
}

contract CheckedDivProperties {
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

contract CheckedSubProperties {
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

contract ModProperties {
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

contract AddModProperties {
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
}

contract MulModProperties {
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
}


contract SignedDivisionProperties {
    // helpers
    function signedDiv(int a, int b) internal pure returns (int res) {
        assembly { res := sdiv(a, b) }
    }

    // properties
    function prove_sign_result(int a, int b) public pure {
        require(b != 0, "Division by zero is not allowed");
        int result = signedDiv(a, b);
        bool expectedSign = (a < 0 && b < 0) || (a > 0 && b > 0);
        assert((result >= 0 && expectedSign) || (result <= 0 && !expectedSign));
    }
    function prove_sdiv_rounds_towards_zero(int a, int b) public pure {
        require(b != 0, "Division by zero is not allowed");
        int result = signedDiv(a, b);
        assert((a % b == 0) || (a / b == (a - (a % b)) / b));
    }
}

contract SignedModuloProperties {
    // helpers
    function signedMod(int a, int b) internal pure returns (int res) {
        require(b != 0, "Modulo by zero is not allowed");
        assembly { res := smod(a, b) }
    }
    function abs(int x) internal pure returns (int) {
        return x >= 0 ? x : -x;
    }


    // properties
    function prove_sign_result(int a, int b) public pure {
        require(b != 0, "Modulo by zero is not allowed");
        int result = signedMod(a, b);
        bool expectedSign = b > 0;
        assert((result >= 0 && expectedSign) || (result <= 0 && !expectedSign));
    }
    function prove_range(int a, int b) public pure {
        require(b != 0, "Modulo by zero is not allowed");
        int result = signedMod(a, b);
        assert(abs(result) < abs(b));
    }
    function prove_smod_non_comm(int a, int b) public pure {
        require(b != 0 && a != 0, "One of the values is zero");
        int resultA = signedMod(a, b);
        int resultB = signedMod(b, a);
        assert(resultA != resultB || abs(a) == abs(b));
    }
    function prove_smod_preserves_sign(int a, int b) public pure {
        require(b != 0, "Modulo by zero is not allowed");
        int result = signedMod(a, b);
        assert((b > 0 && result >= 0) || (b < 0 && result <= 0));
    }
}

contract SignExtendProperties {
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