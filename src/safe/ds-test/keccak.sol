import {DSTest} from "ds-test/test.sol";

contract KeccakProperties is DSTest {

    // --- injectivity ---

    function prove_injectivity_uint256_diff(uint x, uint y) public {
        require(x != y);
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_uint256_same(uint x) public {
        bytes32 k0 = keccak256(abi.encodePacked(x));
        bytes32 k1 = keccak256(abi.encodePacked(x));
        assert(k0 == k1);
    }
    function prove_injectivity_uint128_diff(uint128 x, uint128 y) public {
        require(x != y);
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_uint128_same(uint128 x) public {
        bytes32 k0 = keccak256(abi.encodePacked(x));
        bytes32 k1 = keccak256(abi.encodePacked(x));
        assert(k0 == k1);
    }
    function prove_injectivity_mixed_sign(int128 x, uint256 y) public {
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_mixed_width1(uint128 x, uint256 y) public {
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_mixed_width2(int128 x, int32 y) public {
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_bytes32_diff(bytes32 x, bytes32 y) public {
        require(x != y);
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_bytes32_same(uint128 x) public {
        bytes32 k0 = keccak256(abi.encodePacked(x));
        bytes32 k1 = keccak256(abi.encodePacked(x));
        assert(k0 == k1);
    }
    function prove_injectivity_mixed_bytes(bytes32 x, bytes16 y) public {
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_array_calldata(uint[4] calldata x, uint[4] calldata y) public {
        require(x[0] != y[0] || x[1] != y[1] || x[2] != y[2] || x[3] != y[3]);
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_array_mixed_calldata(uint[4] calldata x, uint[3] calldata y) public {
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_array_memory(uint[4] memory x, uint[4] memory y) public {
        require(x[0] != y[0] || x[1] != y[1] || x[2] != y[2] || x[3] != y[3]);
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_array_mixed_memory(uint[4] memory x, uint[3] memory y) public {
        assert(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(y)));
    }
    function prove_injectivity_dynamic_array_same(bytes memory x) public {
        bytes32 k1 = keccak256(x);
        bytes32 k2 = keccak256(x);
        assert(k1 == k2);
    }

    // --- large gaps ---

    function prove_large_gaps_uint256(uint x) public {
        uint k0 = uint(keccak256(abi.encodePacked(x)));
        uint k1 = uint(keccak256(abi.encodePacked(x + 1)));
        uint diff = k1 > k0 ? k1 - k0 : k0 - k1;
        unchecked { assert(k0 - k1 > 10000); }
    }
    function prove_large_gaps_int256(int x) public {
        uint k0 = uint(keccak256(abi.encodePacked(x)));
        uint k1 = uint(keccak256(abi.encodePacked(x - 1)));
        unchecked { assert(k0 - k1 > 10000); }
    }
}
