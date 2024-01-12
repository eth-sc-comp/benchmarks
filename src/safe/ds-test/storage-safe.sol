import {DSTest} from "ds-test/test.sol";

contract ValueTypesSafe is DSTest {
    uint x;
    uint y;

    function prove_initial_values() public {
        assert(x == 0);
        assert(y == 0);
    }

    function prove_simple_write(uint a) public {
        x = a;
        y = a;
        assert(x == a);
        assert(y == a);
    }

    function prove_write_twice(uint a, uint b) public {
        x = a;
        x = b;
        assert(x == b);
    }

    function prove_stress_value(uint v) public {
        x = v;
        y = x;
        x = y + 1;
        y = x -1;
        x = y * 2;
        y = x / 2;
        assert(y == v);
    }
}

contract MappingPropertiesSafe is DSTest {
    mapping (address => uint) balances;
    mapping (uint => bool) auth;
    mapping (address => mapping (address => uint)) allowance;

    function prove_mapping_access0(address x, address y) public {
        require(x != y);
        balances[x] = 1;
        balances[y] = 2;
        assert(balances[x] != balances[y]);
    }

    function prove_nested_set(address x, address y, uint val) public {
        allowance[x][y] = val;
        assert(allowance[x][y] == val);
    }

    function prove_initial_values(address x, address y) public {
        assert(balances[x] == 0);
        assert(allowance[x][y] == 0);
        assert(auth[uint256(uint160(x))] == false);
    }

    function prove_mixed_symoblic_concrete_writes(address x, uint v) public {
        balances[x] = v;
        balances[address(0)] = balances[x];
        assert(balances[address(0)] == v);
    }

    function prove_stress_mapping(address x, address y, uint val) public {
        balances[x] = val;
        allowance[x][y] = balances[x];
        allowance[y][x] = allowance[x][y];
        auth[uint256(uint160(x))] = true;
        if (auth[uint256(uint160(x))]) {
            balances[y] = allowance[y][x];
            assert(balances[y] == val);
        } else {
            assert(false);
        }
    }
}

contract StructPropertiesSafe is DSTest {
    struct S {
        uint x;
        uint y;
        uint z;
    }

    S s;
    mapping(uint => S) map;

    function prove_read_write(uint a, uint b, uint c) public {
        s.x = a;
        s.y = b;
        s.z = c;
        assert(s.x == a);
        assert(s.y == b);
        assert(s.z == c);
    }

    function prove_mapping_access1(uint idx, uint val) public {
        map[idx].x = val;
        map[idx + 1].y = map[idx].x;
        map[idx - 1].z = map[idx + 1].y;
        assert(map[idx -1].z == val);
    }
}

contract ArrayPropertiesSafe is DSTest {
    uint[] arr1;
    uint[][] arr2;

    function prove_append_one(uint v) public {
        arr1.push(v);
        assert(arr1[0] == v);
        assert(arr1.length == 1);
    }

    function test_cex() public {
        prove_nested_append(0,2);
    }

    function prove_nested_append(uint v, uint w) public {
        arr2.push([v,w]);
        arr2.push();
        arr2.push();

        arr2[1].push(arr2[0][0]);

        arr2[2].push(w);
        arr2[1].push(1);

        assert(arr2.length == 3);

        assert(arr2[0].length == 2);
        assert(arr2[0][0] == v);
        assert(arr2[0][1] == w);

        assert(arr2[1].length == 2);
        assert(arr2[1][0] == v);
        assert(arr2[1][1] == 1);

        assert(arr2[2].length == 1);
        assert(arr2[2][0] == w);
    }
}

contract PackedStoragePropertiesSafe is DSTest {
    uint128 a;
    uint64 b;
    bytes4 c;
    bool d;
    bool e;
    bool f;

    function prove_packed_storage_access(uint128 x, uint64 y) public {
        a = x;
        b = uint64(y);
        c = bytes4(bytes32(uint256(x)));
        d = uint128(uint256(bytes32(c))) > x;
        e = !d;
        f = e || d;
        assert(f);
    }
}
