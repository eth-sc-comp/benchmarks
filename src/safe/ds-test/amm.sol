import {ERC20} from "./erc20.sol";
import "forge-std/Test.sol";

function min(uint x, uint y) returns (uint) {
    return x < y ? x : y;
}

contract AMM is ERC20 {
    ERC20 token0;
    ERC20 token1;

    constructor(address _token0, address _token1) ERC20("lp-token", "LPT", 18) {
        token0 = ERC20(_token0);
        token1 = ERC20(_token1);
    }

    // join allows the caller to exchange amt0 and amt1 tokens for some amount
    // of pool shares. The exact amount of pool shares minted depends on the
    // state of the pool at the time of the call.
    function join(uint amt0, uint amt1) external {
        require(amt0 > 0 && amt1 > 0, "insufficient input amounts");

        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        uint shares = totalSupply == 0
                      ? min(amt0, amt1)
                      : min((totalSupply * amt0) / bal0,
                            (totalSupply * amt1) / bal1);

        balanceOf[msg.sender] += shares;
        totalSupply += shares;

        token0.transferFrom(msg.sender, address(this), amt0);
        token1.transferFrom(msg.sender, address(this), amt1);
    }

    // exit allows the caller to exchange shares pool shares for the
    // proportional amount of the underlying tokens.
    function exit(uint shares) external {
        uint amt0 = (token0.balanceOf(address(this)) * shares) / totalSupply;
        uint amt1 = (token1.balanceOf(address(this)) * shares) / totalSupply;

        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;

        token0.transfer(msg.sender, amt0);
        token1.transfer(msg.sender, amt1);
    }

    // swap allows the caller to exchange amt of src for dst at a price given
    // by the constant product formula: x * y == k.
    function swap(address src, address dst, uint amt) external {
        require(src != dst, "no self swap");
        require(src == address(token0) || src == address(token1), "src not in pair");
        require(dst == address(token0) || dst == address(token1), "dst not in pair");

        uint K = token0.balanceOf(address(this)) * token1.balanceOf(address(this));

        ERC20(src).transferFrom(msg.sender, address(this), amt);

        uint out
          = ERC20(dst).balanceOf(address(this))
          - (K / ERC20(src).balanceOf(address(this)) + 1); // rounding

        ERC20(dst).transfer(msg.sender, out);

        uint KPost = token0.balanceOf(address(this)) * token1.balanceOf(address(this));
        assert(KPost >= K);
    }
}

contract AmmTest is Test {
    ERC20 token0;
    ERC20 token1;
    AMM amm;

    constructor() public {
        token0 = new ERC20("t0", "t0", 18);
        token1 = new ERC20("t1", "t1", 18);
        amm = new AMM(address(token0), address(token1));
    }

    function prove_swap(bool direction, address usr, uint lp0, uint lp1, uint amt) public {
        require(usr != address(this));
        address src = direction ? address(token0) : address(token1);
        address dst = direction ? address(token1) : address(token0);

        // we LP from the test contract
        token0.mint(address(this), lp0);
        token1.mint(address(this), lp1);
        token0.approve(address(amm), type(uint).max);
        token1.approve(address(amm), type(uint).max);
        amm.join(lp0, lp1);

        // give usr some tokens
        ERC20(src).mint(usr, amt);

        // approve amm for usr
        vm.prank(usr);
        token0.approve(address(amm), type(uint).max);
        vm.prank(usr);
        token1.approve(address(amm), type(uint).max);

        /// assertion in swap should never be violated
        vm.prank(usr);
        amm.swap(src, dst, amt);
    }
}
