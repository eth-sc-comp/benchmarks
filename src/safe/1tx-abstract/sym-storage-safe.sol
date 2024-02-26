contract SymStorageSafe {
    mapping (uint => uint) map;
    uint[] arr;

    function prove_mapping(uint u, uint v) public {
        require(u == v);
        assert(map[u] == map[v]);
    }

    function prove_array(uint i, uint j) public {
        require(i == j);
        assert(arr[i] == arr[j]);
    }
}
