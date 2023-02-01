// SPDX-License-Identifier: MIT
// @title Fair Raffle
// @author kaya

%lang starknet

from starkware.starknet.common.syscalls import get_block_number, get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.cairo_builtins import HashBuiltin

const EMPIRIC_RANDOM_ORACLE_ADDRESS = 0x681a206bfb74aa7436b3c5c20d7c9242bc41bc6471365ca9404e738ca8f1f3b;


@storage_var
func reference_point() -> (random_reference: felt){
}

@storage_var
func step_size() -> (step_size: felt){
}

@storage_var
func min_block_number_storage() -> (min_block_number: felt) {
}


@contract_interface
namespace IRandomness {
    func request_random(seed,
                        callback_address,
                        callback_gas_limit,
                        publish_delay,
                        num_words
    ) -> (
        request_id: felt
    ) {
    }
}

@external
func request_my_randomness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    seed, callback_address, callback_gas_limit, publish_delay, num_words
) {
    let (request_id) = IRandomness.request_random(
        EMPIRIC_RANDOM_ORACLE_ADDRESS,
        seed,
        callback_address,
        callback_gas_limit,
        publish_delay,
        num_words,
    );

    let (current_block_number) = get_block_number();
    min_block_number_storage.write(current_block_number + publish_delay);

    return ();
}

@external
func receive_random_words{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    requestor_address, request_id, random_words_len, random_words: felt*
) {
    
    let (caller_address) = get_caller_address();
    assert EMPIRIC_RANDOM_ORACLE_ADDRESS = caller_address;


    let (current_block_number) = get_block_number();
    let (min_block_number) = min_block_number_storage.read();
    assert_le(min_block_number, current_block_number);
    
    let (contract_address) = get_contract_address();
    assert requestor_address = contract_address;
    let random_word = random_words[0];

    return ();
}

@external
func choose_random{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    random_len: felt, random: felt*)->(randomArr_len: felt, randomArr: felt*){    
        return(randomArr_len=random_len, randomArr = random);
    }