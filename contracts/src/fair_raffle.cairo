// SPDX-License-Identifier: MIT
// @title Fair Raffle
// @author kaya
// @author hikmo

%lang starknet

from starkware.starknet.common.syscalls import get_block_number, get_caller_address, get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (assert_le, Uint256, uint256_eq, uint256_add) 
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1

from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math_cmp import is_le_felts

// Interfaces

@contract_interface
namespace INFTContract {
    func owner_of(tokenId: Uint256) -> (owner:felt){
    }
}

// Constants

const EMPIRIC_RANDOM_ORACLE_ADDRESS = 0x681a206bfb74aa7436b3c5c20d7c9242bc41bc6471365ca9404e738ca8f1f3b;
const L1_CONTRACT_ADDRESS = 0x681a206bfb74aa7436b3c5c20d7c9242bc41bc6471365ca9404e738ca8f1f3b;

// Storage Variables

@storage_var
func reference_point() -> (random_reference: felt){
}

@storage_var
func step_size() -> (step_size: felt){
}

@storage_var
func min_block_number_storage() -> (min_block_number: felt) {
}

@storage_var
func id_to_holders(tokenId: Uint256) -> (holder: felt) {
}

@storage_var
func random_choosens(index: felt) -> (random_choosens: felt) {
}



// Interfaces

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

// Views

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (holder: felt){
    let (holder: felt) = id_to_holders.read(tokenId);
    return (holder=holder);
}

@view
func random_choosens{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(index: felt) -> ( nft

//Externals

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
func make_Raffle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    random_len: felt, winner_amount: felt, random: felt)->(randomArr_len: felt, randomArr: felt*){
        local randomArr: felt*;

        
        

        return(randomArr_len=winner_amount, randomArr = randomArr);
}

@external
func get_nft_holders_from_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt,
    total_supply: felt,
) {
    // let (firstId) = Uint(1,0) doesnt work why?
    _get_holder{contract_address=contract_address, total_supply=total_supply}(tokenId=Uint256(1,0));
    return();
}

// Helpers

func _get_holder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contract_address: felt, total_supply: felt} (
    tokenId: Uint256
) {
    let total_supply_uint = Uint256(total_supply, 0);
    let (res) = uint256_eq(total_supply_uint, tokenId);
    if (res == 1) {
        return();
    }
    let (owner) = INFTContract.owner_of(contract_address=contract_address, tokenId=tokenId);
    id_to_holders.write(tokenId, owner);
    let (nextId, car) = uint256_add(tokenId, Uint256(1,0));
    return _get_holder(nextId);
}

// L1-L2 interaction

func init_raffle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    raffleId: felt
) {
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = raffleId;

    send_message_to_l1(
        to_address=L1_CONTRACT_ADDRESS,
        payload_size=1,
        payload=message_payload,
    );

    // todo event

    return();
}

@l1_handler
func finalize_raffle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    from_address: felt, raffle_id: felt, random_number: Uint256
) {
    return();
}

 
