requires "foundry.md"

module DEMO-LEMMAS
    imports FOUNDRY
    imports SET-SYMBOLIC

// #And ( ( { true #Equals VV1_b_3c5818c8 <=Int ( ( 115792089237316195423570985008687907853269984665640564039457584007913129639935 /Int VV0_a_3c5818c8 ) ) }
// #And ( ( { true #Equals VV1_b_3c5818c8 <Int ( ( chop ( ( ( VV0_a_3c5818c8 *Int VV1_b_3c5818c8 ) ) ) /Int 1000000000000000000 ) ) }

    rule X *Int Y <Int pow256 => true requires Y <=Int maxUInt256 /Int X [simplification]
endmodule