import {DSTest} from "ds-test/test.sol";

contract BitwiseAndProperties is DSTest {
    function prove_idempotence(uint a) public pure {
        assert((a & a) == a);
    }
    function prove_commutativity(uint a, uint b) public pure {
        assert((a & b) == (b & a));
    }
    function prove_associativity(uint a, uint b, uint c) public pure {
        assert((a & (b & c)) == ((a & b) & c));
    }
    function prove_annihilation(uint a) public pure {
        assert((a & 0) == 0);
    }
    function prove_identity(uint a) public pure {
        assert((a & ~uint(0)) == a);
    }
}

contract BitwiseOrProperties is DSTest {
    function prove_idempotence(uint a) public pure {
        assert((a | a) == a);
    }
    function prove_commutativity(uint a, uint b) public pure {
        assert((a | b) == (b | a));
    }
    function prove_associativity(uint a, uint b, uint c) public pure {
        assert((a | (b | c)) == ((a | b) | c));
    }
    function prove_dominance(uint a) public pure {
        assert((a | ~uint(0)) == ~uint(0));
    }
    function prove_identity(uint a) public pure {
        assert((a | 0) == a);
    }
}

contract BitwiseXorProperties is DSTest {
    function prove_idempotence(uint a) public pure {
        assert((a ^ 0) == a);
    }

    function prove_self_inversion(uint a) public pure {
        assert((a ^ a) == 0);
    }

    function prove_commutativity(uint a, uint b) public pure {
        assert((a ^ b) == (b ^ a));
    }

    function prove_associativity(uint a, uint b, uint c) public pure {
        assert((a ^ (b ^ c)) == ((a ^ b) ^ c));
    }

    function prove_inversion(uint a) public pure {
        assert((a ^ ~uint(0)) == ~a);
    }
}

contract BitwiseNotProperties is DSTest {
    function prove_double_negation(uint a) public pure {
        assert(~~a == a);
    }

    function prove_inversion(uint a) public pure {
        uint not_a = ~a;
        assert(a + not_a == ~uint(0));
    }
}

contract BitwiseShlProperties is DSTest {
    function prove_zero_shift(uint a) public pure {
        assert((a << 0) == a);
    }

    function prove_distributivity_over_addition(uint a, uint b, uint c) public pure {
        assert(((a + b) << c) == ((a << c) + (b << c)));
    }

    function prove_multiplication_by_powers_of_two(uint a) public pure {
        assert((a << 1) == a * 2);
    }

    function prove_combinability_of_shifts(uint a, uint b, uint c) public pure {
        assert(((a << b) << c) == (a << (b + c)));
    }
}

contract BitwiseShrProperties is DSTest {
    function prove_zero_shift(uint a) public pure {
        assert((a >> 0) == a);
    }

    function prove_division_by_powers_of_two(uint a) public pure {
        assert((a >> 1) == a / 2);
    }

    function prove_combinability_of_shifts(uint a, uint b, uint c) public pure {
        assert(((a >> b) >> c) == (a >> (b + c)));
    }
}

// TODO: SAR is so weird, what should the behaviour even be?
contract BitwiseSarProperties is DSTest {
    function sar(int num, uint shift) internal pure returns (int) {
        int res;
        assembly {
            res := sar(shift, num)
        }

    }
    // TODO: both halmos and hevm report a cex here
    //function prove_zero_shift(int a) public pure {
        //assert(sar(a, 0) == a);
    //}

    // TODO: both halmos and hevm report a cex here
    //function prove_division_by_powers_of_two_for_non_negative(int a, uint shift) public pure {
        //require(a >= 0);
        //assert(sar(a, 1) == a / int256(2**shift));
    //}

    // TODO: both halmos and hevm report a cex here
    //function prove_effect_on_negative_numbers(int a, uint shift) public pure {
        //require(a < 0);
        //assert(sar(a,shift) == a >> shift);
    //}

    // TODO: is this true?
    //function prove_combinability_of_shifts(int a, uint b, uint c) public pure {
        //assert(((a >> b) >> c) == (a >> (b + c)));
    //}
}
