// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

/// @notice Sacred Geometry puzzle by jtriley.eth, reproduced with permission of the author
/// featured on https://www.curta.wtf/puzzle/14
/// write-up: https://twitter.com/jtriley_eth/status/1683203592344473601
/// quick summary:
/// - implements a stack machine with add, sub, mul, div, and swap1-swap7
/// - an 8-byte input is provided to the stack machine
/// - the solution is interpreted as bytecode and executed by the stack machine
/// - to pass the challenge, the solution must produce one of the three primes

/* <<EOF SacredGeometry.huff

//! ```
//!                                Sacred Geometry
//!
//!                                    %@@@@@/
//!                                @@@@@@   @@@@@@
//!                           ,@@@, @@&       @@& (@@@
//!                       %@@@    @@*           #@@   .@@@(
//!                   @@@%     .@@                ,@@      @@@@
//!              ,@@@*       /@@                     @@.       #@@@.
//!              @@@@@@    @@@                         @@#   .@@@@@@
//!              @#     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%     @@
//!              @#     #@*@@                           @@%@      @@
//!              @#    .@#  @@                        *@@  @@     @@
//!              @#    @@    *@@                     @@     @@    @@
//!              @#   @@       @@                   @@       @@   @@
//!              @#  @@         %@(               @@/         @@  @@
//!              @# @@            @@             @@            @@ @@
//!              @#@@              @@.         (@&             .@&@@
//!              @@@                ,@@       @@                *@@@
//!              @@,                  @@    .@@                  &@@
//!              @@@@@@@%*             %@% @@.             /%@@@@@@@
//!                 &@@@    ,(&@@@@@@@@@@@@@@@@@@@@@@@&/.    @@@#
//!                     /@@@.            (@.            *@@@,
//!                          @@@#        (@.        &@@@
//!                              @@@@    (@.    @@@%
//!                                  (@@@(@/@@@,
//!                                      .@
//! ```
//!
//! ## Memory Layout
//!
//! | index  | value             |
//! | ------ | ----------------- |
//! | 0x0000 | op_halt_dest      |
//! | 0x0020 | op_add_dest       |
//! | 0x0040 | op_sub_dest       |
//! | 0x0060 | op_mul_dest       |
//! | 0x0080 | op_div_dest       |
//! | 0x00a0 | op_swap1_dest     |
//! | 0x00c0 | op_swap2_dest     |
//! | 0x00e0 | op_swap3_dest     |
//! | 0x0100 | op_swap4_dest     |
//! | 0x0120 | op_swap5_dest     |
//! | 0x0140 | op_swap6_dest     |
//! | 0x0160 | op_swap7_dest     |
//! | 0x0180 | program_counter   |
//! | 0x01a0 | executable        |
//! | 0x01c0 | virtual_stack_ptr |
//!
//! ## Instruction Set
//!
//! | opcode | byte |
//! | ------ | ---- |
//! | HALT   | 0x00 |
//! | ADD    | 0x01 |
//! | SUB    | 0x02 |
//! | MUL    | 0x03 |
//! | DIV    | 0x04 |
//! | SWAP1  | 0x05 |
//! | SWAP2  | 0x06 |
//! | SWAP3  | 0x07 |
//! | SWAP4  | 0x08 |
//! | SWAP5  | 0x09 |
//! | SWAP6  | 0x0a |
//! | SWAP7  | 0x0b |

// --- Application Binary Interface ---

#define function name() pure returns (string)
#define function generate(address) pure returns (uint256)
#define function verify(uint256,uint256) pure returns (bool)

// --- Constants ---

#define constant NAME_STR = 0x0f5361637265642047656f6d65747279
#define constant MAX_VALUE = 0x06
#define constant VIRTUAL_STACK_PTR = 0x07
#define constant OPCODE_MOD = 0x0c

#define constant PC_PTR = 0x0180
#define constant EXECUTABLE_PTR = 0x01a0
#define constant VIRTUAL_STACK_PTR_PTR = 0x01c0

#define constant ARG0_CD_PTR = 0x04
#define constant ARG1_CD_PTR = 0x24

#define constant PRIME_0 = 0x0d
#define constant PRIME_1 = 0x11
#define constant PRIME_2 = 0x13

#define constant INPUT_0 = 0x1f
#define constant INPUT_1 = 0x1e
#define constant INPUT_2 = 0x1d
#define constant INPUT_3 = 0x1c
#define constant INPUT_4 = 0x1b
#define constant INPUT_5 = 0x1a
#define constant INPUT_6 = 0x19
#define constant INPUT_7 = 0x18

// --- Macros ---

/// ## Entry Point
///
/// ### Directives
///
/// 1. Dispatch function by selector.
/// 2. Revert if selector is not matched.
///
/// ### Panics
///
/// - When selector is not matched.
/// - When `VERIFY` panics.
#define macro MAIN() = takes (0) returns (0) {
    0x00 calldataload 0xe0 shr
    dup1 __FUNC_SIG(name) eq is_name jumpi
    dup1 __FUNC_SIG(generate) eq is_generate jumpi
    dup1 __FUNC_SIG(verify) eq is_verify jumpi
    0x00 0x00 revert

    is_name:
        NAME()
    is_generate:
        GENERATE()
    is_verify:
        VERIFY()
}

/// ## Return Name
///
/// ### Directives
///
/// 1. Store name in memory.
/// 2. Return from memory.
#define macro NAME() = takes (0) returns (0) {
    0x20                        // [ptr]
    0x00                        // [mem_ptr, ptr]
    mstore                      // []
    [NAME_STR]                  // [name]
    0x2f                        // [mem_ptr, name]
    mstore                      // []
    0x60                        // [mem_len]
    0x00                        // [mem_ptr, mem_len]
    return                      // []
}

/// ## Generate Random Number
///
/// ### Directives
///
/// 1. Load seed from calldata.
/// 2. Generate 8 bytes with `GEN_BYTE`.
/// 3. Return the bytes, left padded in a single uint256.
#define macro GENERATE() = takes (0) returns (0) {
    0x04                        // [seed_cd_ptr]
    calldataload                // [seed]
    GEN_BYTE(INPUT_0)           // [seed]
    GEN_BYTE(INPUT_1)           // [seed]
    GEN_BYTE(INPUT_2)           // [seed]
    GEN_BYTE(INPUT_3)           // [seed]
    GEN_BYTE(INPUT_4)           // [seed]
    GEN_BYTE(INPUT_5)           // [seed]
    GEN_BYTE(INPUT_6)           // [seed]
    GEN_BYTE(INPUT_7)           // [seed]
    0x20                        // [mem_len, seed]
    0x00                        // [mem_ptr, mem_len, seed]
    return                      // []
}

/// ## Verify Solution
///
/// ### Directives
///
/// 1. Initialize the VM with `INITIALIZE_VM`.
/// 2. Start execution loop.
/// 3. Get current opcode with `GET_OPCODE`.
/// 4. Increment program counter with `INCREMENT_PC`.
/// 5. Dispatch opcode with `DISPATCH_OPCODE`.
/// 6. Based on opcode, perform operation.
/// 7. If the opcode is not HALT, jump to exec_start, continue at step 3.
/// 8. If the opcode is HALT, check the output with `CHECK_OUTPUT`.
/// 9. If the output is correct, return true, else return false.
///
/// ### Panics
///
/// - When the stack underflows.
#define macro VERIFY() = takes (0) returns (0) {
    INITIALIZE_VM()             // [input_0, input_1, input_2, input_3, input_4, input_5, input_6, input_7]

    exec_start:                 // [..inputs]
        GET_OPCODE()            // [opcode, ..inputs]
        INCREMENT_PC()          // [opcode, ..inputs]
        DISPATCH_OPCODE()       // []

    op_add:                     // [a, b, ..inputs]
        DEC_VIRTUAL_STACK_PTR() // [a, b, ..inputs]
        add                     // [sum, ..inputs]
        exec_start jump         // [sum, ..inputs]

    op_sub:                     // [a, b, ..inputs]
        DEC_VIRTUAL_STACK_PTR() // [a, b, ..inputs]
        sub                     // [difference, ..inputs]
        exec_start jump         // [difference, ..inputs]

    op_mul:                     // [a, b, ..inputs]
        DEC_VIRTUAL_STACK_PTR() // [a, b, ..inputs]
        mul                     // [prod, ..inputs]
        exec_start jump         // [prod, ..inputs]

    op_div:                     // [a, b, ..inputs]
        DEC_VIRTUAL_STACK_PTR() // [a, b, ..inputs]
        div                     // [quotient, ..inputs]
        exec_start jump         // [quotient, ..inputs]

    op_swap1:                   // [a, b, ..inputs]
        swap1                   // [b, a, ..inputs]
        exec_start jump         // [b, a, ..inputs]

    op_swap2:                   // [a, _, b, ..inputs]
        swap2                   // [b, _, a, ..inputs]
        exec_start jump         // [b, _, a, ..inputs]

    op_swap3:                   // [a, _, _, b, ..inputs]
        swap3                   // [b, _, _, a, ..inputs]
        exec_start jump         // [b, _, _, a, ..inputs]

    op_swap4:                   // [a, _, _, _, b, ..inputs]
        swap4                   // [b, _, _, _, a, ..inputs]
        exec_start jump         // [b, _, _, _, a, ..inputs]

    op_swap5:                   // [a, _, _, _, _, b, ..inputs]
        swap5                   // [b, _, _, _, _, a, ..inputs]
        exec_start jump         // [b, _, _, _, _, a, ..inputs]

    op_swap6:                   // [a, _, _, _, _, _, b, ..inputs]
        swap6                   // [b, _, _, _, _, _, a, ..inputs]
        exec_start jump         // [b, _, _, _, _, _, a, ..inputs]

    op_swap7:                   // [a, _, _, _, _, _, _, b]
        swap7                   // [b, _, _, _, _, _, _, a]
        exec_start jump         // [b, _, _, _, _, _, _, a]

    op_halt:                    // [result]
        CHECK_OUTPUT()          // [is_valid_prime]
        0x00                    // [mem_ptr, is_valid_prime]
        mstore                  // []
        0x20                    // [mem_len]
        0x00                    // [mem_ptr, mem_len]
        return                  // []
}

// --- Virtual Machine Operations ---

/// ## Initialize VM
///
/// > Note: The program counter (`memory[0x0180]`) is implicitly initialized to 0.
///
/// ### Directives
///
/// 1. Store the opcode jumptable in memory.
/// 2. Write the executable to memory.
/// 3. Write the virtual stack depth to memory.
/// 4. Read the program input from calldata.
/// 5. Get and push each random number to the stack with `PUSH_NUMBER`.
#define macro INITIALIZE_VM() = takes (0) returns (1) {
    __tablesize(OPCODE_TABLE)   // [opcode_table_len]
    __tablestart(OPCODE_TABLE)  // [opcode_table_ptr, opcode_table_len]
    0x00                        // [mem_ptr, opcode_table_ptr, opcode_table_len]
    codecopy                    // []

    [ARG1_CD_PTR]               // [executable_cd_ptr]
    calldataload                // [executable]
    [EXECUTABLE_PTR]            // [mem_ptr, executable]
    mstore                      // []

    [VIRTUAL_STACK_PTR]         // [virtual_stack_depth]
    [VIRTUAL_STACK_PTR_PTR]     // [virtual_stack_ptr_ptr, virtual_stack_depth]
    mstore                      // []

    [ARG0_CD_PTR]               // [program_input_cd_ptr]
    calldataload                // [program_input]
    PUSH_NUMBER(INPUT_7)        // [program_input, input_7]
    PUSH_NUMBER(INPUT_6)        // [program_input, input_6, input_7]
    PUSH_NUMBER(INPUT_5)        // [program_input, input_5, input_6, input_7]
    PUSH_NUMBER(INPUT_4)        // [program_input, input_4, input_5, input_6, input_7]
    PUSH_NUMBER(INPUT_3)        // [program_input, input_3, input_4, input_5, input_6, input_7]
    PUSH_NUMBER(INPUT_2)        // [program_input, input_2, input_3, input_4, input_5, input_6, input_7]
    PUSH_NUMBER(INPUT_1)        // [program_input, input_1, input_2, input_3, input_4, input_5, input_6, input_7]
    PUSH_NUMBER(INPUT_0)        // [program_input, input_0, input_1, input_2, input_3, input_4, input_5, input_6, input_7]
    pop                         // [input_0, input_1, input_2, input_3, input_4, input_5, input_6, input_7]
}

/// ## Get Opcode
///
/// ### Directives
///
/// 1. Read the program counter from memory.
/// 2. Add the executable offer to the program counter.
/// 3. Read the opcode from memory.
/// 4. Shift the opcode to the right by 248 bits.
/// 5. Mask the opcode with seven.
#define macro GET_OPCODE() = takes (0) returns (1) {
    [PC_PTR]                    // [program_counter_ptr]
    mload                       // [program_counter]
    [EXECUTABLE_PTR]            // [executable_start, program_counter]
    add                         // [opcode_ptr]
    mload                       // [opcode_word]
    0xf8                        // [shift, opcode_word]
    shr                         // [opcode]
    [OPCODE_MOD]                // [opcode_mod, opcode]
    swap1                       // [opcode, opcode_mod]
    mod                         // [valid_opcode]
}

/// ## Increment Program Counter
///
/// ### Directives
///
/// 1. Read the program counter from memory.
/// 2. Add one to the program counter.
/// 3. Write the new program counter to memory.
#define macro INCREMENT_PC() = takes (0) returns (0) {
    [PC_PTR]                    // [program_counter_ptr, opcode]
    dup1                        // [program_counter_ptr, program_counter_ptr, opcode]
    mload                       // [program_counter, program_counter_ptr, opcode]
    0x01                        // [one, program_counter, program_counter_ptr, opcode]
    add                         // [new_program_counter, program_counter_ptr, opcode]
    swap1                       // [program_counter_ptr, new_program_counter, opcode]
    mstore                      // [opcode]
}

/// ## Dispatch Opcode
///
/// ### Directives
///
/// 1. Shift the opcode to the left by five bits.
/// 2. Read the opcode from the jumptable in memory.
#define macro DISPATCH_OPCODE() = takes (1) returns (0) {
    0x05                        // [shift, opcode]
    shl                         // [op_dispatch_ptr]
    mload                       // [op_dispatch_dest]
    jump                        // []
}

/// ## Decrement Virtual Stack Pointer
///
/// ### Directives
///
/// 1. Read the virtual stack pointer from memory.
/// 2. Subtract one from the virtual stack pointer.
/// 3. Write the new virtual stack pointer to memory.
#define macro DEC_VIRTUAL_STACK_PTR() = takes (0) returns (0) {
    [VIRTUAL_STACK_PTR_PTR]     // [virtual_stack_ptr_ptr]
    0x01                        // [one, virtual_stack_ptr_ptr]
    dup2                        // [virtual_stack_ptr_ptr, one, virtual_stack_ptr_ptr]
    mload                       // [virtual_stack_ptr, one, virtual_stack_ptr_ptr]
    sub                         // [new_virtual_stack_ptr, virtual_stack_ptr_ptr]
    swap1                       // [virtual_stack_ptr_ptr, new_virtual_stack_ptr]
    mstore                      // []
}

/// ## Check the Program Output
///
/// ### Directives
///
/// 1. Checks if the result is equal to prime 0.
/// 2. Checks if the result is equal to prime 1.
/// 3. Checks if the result is equal to prime 2.
/// 4. Accumulates the result of the three checks.
/// 5. Checks if the stack is empty.
/// 6. Accumulates the result of the two checks.
#define macro CHECK_OUTPUT() = takes (1) returns (1) {
    // takes:                   // [result]
    dup1 dup1                   // [result, result, result]
    [PRIME_0]                   // [prime_0, result, result, result]
    eq                          // [is_prime_0, result, result]

    swap1                       // [result, is_prime_0, result]
    [PRIME_1]                   // [prime_1, result, is_prime_0, result]
    eq                          // [is_prime_1, is_prime_0, result]

    swap2                       // [result, is_prime_1, is_prime_0]
    [PRIME_2]                   // [prime_2, result, is_prime_1, is_prime_0]
    eq                          // [is_prime_2, is_prime_1, is_prime_0]

    or or                       // [is_valid_prime]

    [VIRTUAL_STACK_PTR_PTR]     // [virtual_stack_ptr_ptr, is_valid_prime]
    mload                       // [virtual_stack_ptr, is_valid_prime]
    iszero                      // [is_stack_empty, is_valid_prime]
    and                         // [is_valid_output]
}

// --- Utilities ---

/// ## Generate Byte of Pseudorandom Number
///
/// ### Directives
///
/// 1. Extract a byte from the `seed` index `idx`.
/// 2. Modulo the byte by the `MAX_VALUE`.
/// 3. Add one to the result.
/// 4. Store the result in memory.
#define macro GEN_BYTE(idx) = takes (1) returns (1) {
    // takes:                   // [seed]
    [MAX_VALUE]                 // [mod, seed]
    dup2                        // [seed, mod, seed]
    <idx>                       // [idx, seed, mod, seed]
    byte                        // [byte, mod, seed]
    mod                         // [rand, seed]
    0x01                        // [one, rand, seed]
    add                         // [rand, seed]
    <idx>                       // [idx, rand, seed]
    mstore8                     // [seed]
}

/// ## Push Pseudorandom Number to Stack
///
/// ### Directives
///
/// 1. Extract a byte from the `program_input` index `idx`.
#define macro PUSH_NUMBER(idx) = takes (1) returns (2) {
    // takes:                   // [program_input]
    dup1                        // [program_input, program_input]
    <idx>                       // [idx, program_input, program_input]
    byte                        // [byte, program_input]
    swap1                       // [program_input, byte]
}

// --- Jumptable ---

/// ## Opcode Jumptable
///
/// Maps opcodes to jumptable indices in memory.
#define jumptable OPCODE_TABLE {
    op_halt                     // 0x0000
    op_add                      // 0x0020
    op_sub                      // 0x0040
    op_mul                      // 0x0060
    op_div                      // 0x0080
    op_swap1                    // 0x00a0
    op_swap2                    // 0x00c0
    op_swap3                    // 0x00e0
    op_swap4                    // 0x0100
    op_swap5                    // 0x0120
    op_swap6                    // 0x0140
    op_swap7                    // 0x0160
}

EOF SacredGeometry.huff */

interface Challenge {
    function name() external pure returns (string memory);
    function generate(address) external pure returns (uint256);
    function verify(uint256 input, uint256 solution) external pure returns (bool);
}

contract SacredGeometryTest is Test {
    Challenge public challenge;

    // obtained with challenge.generate(address(uint160(uint256(keccak256(bytes("Sacred Geometry"))))))
    uint256 constant INPUT = 0x0205010104030306;

    function setUp() public {
        // obtained with `huffc -b SacredGeometry.huff`
        bytes memory deploymentBytecode = hex"61032780600a3d393df360003560e01c806306fdde031461002c5780632fa61cd81461004b57806341161b10146100bc5760006000fd5b60206000526f0f5361637265642047656f6d65747279602f5260606000f35b600435600681601f1a06600101601f53600681601e1a06600101601e53600681601d1a06600101601d53600681601c1a06600101601c53600681601b1a06600101601b53600681601a1a06600101601a5360068160191a0660010160195360068160181a0660010160185360206000f35b6101806101a76000396024356101a05260076101c0526004358060181a908060191a9080601a1a9080601b1a9080601c1a9080601d1a9080601e1a9080601f1a90505b610180516101a0015160f81c600c90066101808051600101905260051b51565b6101c060018151039052016100ff565b6101c060018151039052036100ff565b6101c060018151039052026100ff565b6101c060018151039052046100ff565b906100ff565b916100ff565b926100ff565b936100ff565b946100ff565b956100ff565b966100ff565b8080600d14906011149160131417176101c051151660005260206000f30000000000000000000000000000000000000000000000000000000000000189000000000000000000000000000000000000000000000000000000000000011f000000000000000000000000000000000000000000000000000000000000012f000000000000000000000000000000000000000000000000000000000000013f000000000000000000000000000000000000000000000000000000000000014f000000000000000000000000000000000000000000000000000000000000015f0000000000000000000000000000000000000000000000000000000000000165000000000000000000000000000000000000000000000000000000000000016b00000000000000000000000000000000000000000000000000000000000001710000000000000000000000000000000000000000000000000000000000000177000000000000000000000000000000000000000000000000000000000000017d0000000000000000000000000000000000000000000000000000000000000183";

        // deploy the challenge contract
        address addr;
        assembly {
            addr := create(0, add(deploymentBytecode, 0x20), mload(deploymentBytecode))
        }

        challenge = Challenge(address(addr));
    }

    /// @dev sanity check to verify that the contract is deployed correctly
    function test_name() public {
        string memory name = challenge.name();
        assertEq(keccak256(bytes(name)), keccak256(bytes("Sacred Geometry")));
    }

    /// brute force fuzz run can occasionally find a solution
    /// forge-config: default.fuzz.runs = 1000000
    // function testFuzz_verify(uint256 solution) public {
    //     try challenge.verify(INPUT, solution) returns (bool accepted) {
    //         assertEq(accepted, false);
    //     } catch {
    //         // pass
    //     }
    // }

    /// @dev uncomment to validate a solution
    // function test_verify_solution() public view {
    //     uint256 solution = 0x3103291d2ac871df13000000000000000000000000000000000000000000000;
    //     assert(challenge.verify(INPUT, solution));
    // }

    function prove_verify(uint256 solution) public view {
        assert(!challenge.verify(INPUT, solution));
    }
}
