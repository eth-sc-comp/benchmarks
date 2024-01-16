contract SymStorageUnsafe {
    uint x;
    mapping (uint => uint) map;
    uint[] arr;

    function prove_value(uint v) public {
        assert(x == 10);
    }

    function prove_mapping(uint u, uint v) public {
        assert(map[u] == map[v]);
    }

    function prove_array(uint i, uint j) public {
        assert(arr[i] == arr[j]);
    }
}
