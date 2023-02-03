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

from starkware.cairo.common.math import (
    assert_nn, assert_nn_le, assert_not_zero, unsigned_div_rem)


// Interfaces

@contract_interface
namespace INFTContract {
    func ownerOf(tokenId: Uint256) -> (owner:felt){
    }
}

// Events

@event
func raffle_initiated(
    attendees_len: felt,
    attendees: felt*,
) {
}

@event
func raffle_winners(
    raffle_id: felt,
    winner_list_len: felt,
    winner_list: felt*){}
// Constants

const L1_CONTRACT_ADDRESS = 0x02e67b27a2c006081779479faed680603981cbb7db2030ba6392be30a046734c;

// Enumarations
// **************************

// For raffle status
const NOT_CREATED = 0;
const WAITING_L1 = 1;
const FINALIZED = 2;

// For raffle type
const CUSTOM_LIST = 0;
const NFT_HOLDERS = 1;
const TWITTER_API = 2;

// **************************

// Structs

struct RaffleMaker {
    address: felt,
    // todo add starknet-id integration
}

struct Raffle {
    // Can be either INITIATED, WAITING_L1, or FINALIZED
    status: felt,
    // O by default
    random_number: felt,
    raffle_maker: RaffleMaker,
    // Given by raffle make in the restriction that winner_count < len(attendees)
    winner_count: felt,
    // Time where attendees are certain
    init_time: felt,
    // Time when random_number arrives l2
    final_time: felt,
    // For NFT HOLDERS Raffle Type
    attendees_list_id: felt,
    attendees_len: felt,
    // For CUSTOM_LIST And TWITTER_API Raffle Type
    ipfs_hash: felt,
}

// Storage Variables

@storage_var
func id_to_holders(tokenId: Uint256) -> (holder: felt) {
}

@storage_var
func raffles(raffle_id: felt) -> (raffle: Raffle){
}

@storage_var
func raffles_counter() -> (res: felt) {
}

//constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    raffles_counter.write(0);
    return ();
}

// Views

@view
func get_raffle_status{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(raffle_id: felt) -> (status: felt){
    let (raffle) = raffles.read(raffle_id);
    return(status=raffle.status);
}

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (holder: felt){
    let (holder: felt) = id_to_holders.read(tokenId);
    return (holder=holder);
}

//Externals

@external
func choose_random{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    random_len: felt, random: felt*)->(randomArr_len: felt, randomArr: felt*){    
        return(randomArr_len=random_len, randomArr = random);
}

@external
func get_nft_holders_from_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt,
    total_supply: felt,
) -> () {
    alloc_locals;
    local holders: felt*;
    _get_holder{contract_address=contract_address, total_supply=total_supply, 
        holders=holders
        }(tokenId=Uint256(1,0));
    return();
}

// Helpers

func _get_holder{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr, 
    contract_address: felt, 
    total_supply: felt,
    holders: felt*,
} (
    tokenId: Uint256
) {
    let total_supply_uint = Uint256(total_supply, 0);
    let (owner) = INFTContract.ownerOf(contract_address=contract_address, tokenId=tokenId);
    id_to_holders.write(tokenId, owner);
    let (nextId, carry) = uint256_add(tokenId, Uint256(1,0));
    assert holders[nextId.low - 1] = owner;
    let (res) = uint256_eq(total_supply_uint, tokenId);
    if (res == 1) {
        raffle_initiated.emit(attendees_len=total_supply, attendees=holders);
        return();
    }
    return _get_holder(nextId);
}

// L1-L2 interaction

func init_raffle_random_call{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
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

    pick_winner(raffle_id =  raffle_id, random_number = random_number);
    return();
}

//Helpers

func pick_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    raffle_id: felt, random_number: Uint256
) {
    let (raffle) = raffles.read(raffle_id);
    let (attendees_len) = raffle.read(attendees_len);
    let (winner_count) = raffle.read(winner_count);

    let (t_div_winner_count, reference_point) = unsigned_div_rem(random_number.low, attendees_len );
    let (t_div_winner_count_high, step_size) = unsigned_div_rem(random_number.high, attendees_len );

    alloc_locals;
    local winner_array: felt* ;
    let (winner_array) = choose_random(0,winner_count, attendees_len, reference_point, step_size, winner_array);
    raffle_winners.emit(raffle_id = raffle_id , winner_list = winner_array);
    return();
}

func choose_random{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    current_index: felt, winner_count: felt, attendees_len: felt, reference_point: felt, step_size: felt, winner_array : felt*, 
){

    if(winner_count==current_index){
        return(winner_array=winner_array);
    }

    let (wont_be_used, new_element) = unsigned_div_rem( (reference_point+step_size), attendees_len );
    winner_array[current_index] = new_element;

    //Checking if we select the same person again
    let (wont_be_used_too, check) = unsigned_div_rem( (reference_point+(step_size*current_index)), attendees_len );

    if(check==0){ 
        step_size = step_size+1;
        current_index = current_index-1;
    }
    choose_random((current_index+1),winner_count, attendees_len, reference_point, step_size, winner_array);
    return(winner_array=winner_array);
}