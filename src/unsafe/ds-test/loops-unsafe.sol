import {DSTest} from "ds-test/test.sol";

contract LoopsUnsafe is DSTest {
    function prove_bounded_smol(uint x) public {
        require (x < 5);
        uint j;
        for (uint i = 0; i < x; i++) {
            j ++;
        }
        assert(j != x);
    }

    function prove_bounded_med(uint x) public {
        require (x < 100);
        uint j;
        for (uint i = 0; i < x; i++) {
            j ++;
        }
        assert(j != x);
    }

    function prove_bounded_large(uint x) public {
        require (x < 10_000);
        uint j;
        for (uint i = 0; i < x; i++) {
            j ++;
        }
        assert(j != x);
    }

    function prove_unbounded(uint x) public {
        uint j;
        for (uint i = 0; i < x; i++) {
            j ++;
        }
        assert(j != x);
    }
}
