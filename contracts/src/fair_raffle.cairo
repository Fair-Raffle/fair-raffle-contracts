// SPDX-License-Identifier: MIT
// @title Fair Raffle
// @author kaya
// @author hikmo

%lang starknet

from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address, get_block_timestamp)
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
    raffleId: felt,
    raffleType: felt,
    attendees_len: felt,
    nft_contract_address: felt,
    ipfs_hash: felt,
    timestamp: felt,
    made_by: felt,
    winner_count: felt
) {
}

@event
func raffle_winners(
    raffle_id: felt,
    winner_list_len: felt,
    winner_list: felt*, 
){
}


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
    // Can be either NOT_CREATED, WAITING_L1, or FINALIZED
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
    nft_contract_address: felt,
    // For CUSTOM_LIST And TWITTER_API Raffle Type
    ipfs_hash: felt,
    // For NFT HOLDERS Raffle Type
    attendees_list_id: felt,
    attendees_len: felt,
}

// Storage Variables

@storage_var
func id_to_holders(raffleId: felt, tokenId: Uint256) -> (holder: felt) {
}

@storage_var
func raffles(raffle_id: felt) -> (raffle: Raffle){
}

@storage_var
func raffles_counter() -> (res: felt) {
}

@storage_var
func random_test() -> (random: felt){
}

@storage_var
func raffle_id_test() -> (raffle_id: felt){
}

@storage_var
func l1_contract_address() -> (address: felt) {
}

@storage_var
func results(raffleId: felt) -> (random_number: felt) {
}



//constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_contract_address_: felt
) {
    l1_contract_address.write(l1_contract_address_);
    raffles_counter.write(0);
    return ();
}

// Views

@view
func get_l1_address{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (l1_address: felt){
    let (l1_address) = l1_contract_address.read();
    return(l1_address=l1_address);
}

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
}(raffleId: felt, tokenId: Uint256) -> (holder: felt){
    let (holder: felt) = id_to_holders.read(raffleId, tokenId);
    return (holder=holder);
}

@view
func get_reuslt{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(raffleId: felt) -> (random_number: felt){
    let (random_number: felt) = results.read(raffleId);
    return (random_number=random_number);
}

// test views

@view
func get_raffle_id_test{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (raffle_id: felt){
    let (raffle_id) = raffle_id_test.read();
    return(raffle_id=raffle_id);
}

@view
func get_random_test{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (random: felt){
    let (random) = random_test.read();
    return(random=random);
}

//Externals

// For raffle of nft holders
@external
func init_raffle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt,
    total_supply: felt,
    winner_count: felt,
) {
    alloc_locals;
    let (counter: felt) = raffles_counter.read();
    raffles_counter.write(counter + 1);
    let (block_timestamp) = get_block_timestamp();
    let (caller) = get_caller_address();
    let raffle_maker = RaffleMaker(
        address=caller,
    );
    let raffle_created = Raffle(
        status=WAITING_L1,
        random_number=0,
        raffle_maker=raffle_maker,
        winner_count=winner_count,
        init_time=block_timestamp,
        final_time=0,
        nft_contract_address=contract_address,
        ipfs_hash=0,
        attendees_list_id=0,
        attendees_len=total_supply,
        
    );
    raffles.write(counter, raffle_created);
    get_nft_holders_from_contract(contract_address, total_supply, counter);
    raffle_initiated.emit(
        counter,
        NFT_HOLDERS,
        total_supply,
        contract_address,
        0,
        block_timestamp,
        caller,
        winner_count
    );
    return();
}

// external for test purpose should be internal
@external
func get_nft_holders_from_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt,
    total_supply: felt,
    raffleId: felt
) -> () {
    //alloc_locals;
    //let holders: felt* = alloc();
    _get_holder{contract_address=contract_address, total_supply=total_supply, 
        //holders=holders
        }(raffleId=raffleId,tokenId=Uint256(1,0));
    return();
}

// Helpers

func _get_holder{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr, 
    contract_address: felt, 
    total_supply: felt,
    //holders: felt*,
} (
    raffleId: felt,
    tokenId: Uint256,
) {
    alloc_locals;
    let total_supply_uint = Uint256(total_supply, 0);
    let (owner) = INFTContract.ownerOf(contract_address=contract_address, tokenId=tokenId);
    id_to_holders.write(raffleId, tokenId, owner);
    let (nextId, carry) = uint256_add(tokenId, Uint256(1,0));
    //assert holders[nextId.low - 1] = owner;
    let (res) = uint256_eq(total_supply_uint, tokenId);
    if (res == 1) {
        //raffle_initiated.emit(attendees_len=total_supply, attendees=holders);
        return();
    }
    return _get_holder(raffleId, nextId);
}

//Owner functions

@external
func change_l1_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_address: felt,
) {
    l1_contract_address.write(l1_address);
    return();
}

// TESTING

@external
func test_l1_call{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    raffleId: felt
) {
    init_raffle_random_call(raffleId=raffleId);
    return();
}

// L1-L2 interaction

func init_raffle_random_call{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    raffleId: felt
) {
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = raffleId;

    let (ctc_address: felt) = l1_contract_address.read();

    send_message_to_l1(
        to_address=ctc_address,
        payload_size=1,
        payload=message_payload,
    );

    // todo event

    return();
}

@l1_handler
func finalize_raffle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    from_address: felt, raffle_id: felt, random_number: felt
) {
    random_test.write(random_number);
    raffle_id_test.write(raffle_id);
    pick_winner(raffle_id =  raffle_id, random_number = Uint256(random_number, random_number));
    return();
}

//Helpers

func pick_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    raffle_id: felt, random_number: Uint256
) {
    alloc_locals;
    let (raffle) = raffles.read(raffle_id);
    let attendees_len = raffle.attendees_len;
    local winner_count: felt = raffle.winner_count;

    let (t_div_winner_count, reference_point) = unsigned_div_rem(random_number.low, attendees_len );
    let (t_div_winner_count_high, step_size) = unsigned_div_rem(random_number.high, attendees_len );

    let (winner_array: felt*) = alloc();
    choose_random(0,winner_count, attendees_len, reference_point, step_size, winner_array);
    raffle_winners.emit(raffle_id = raffle_id ,winner_list_len = winner_count, winner_list = winner_array);
    return();
}

func choose_random{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    current_index: felt, winner_count: felt, attendees_len: felt, reference_point: felt, step_size: felt, winner_array : felt*, 
){

    if(winner_count==current_index){
        return();
    }

    let (wont_be_used, new_element) = unsigned_div_rem( (reference_point+step_size), attendees_len );
    assert winner_array[current_index] = new_element;

    //Checking if we select the same person again
    let (wont_be_used_too, check) = unsigned_div_rem( (reference_point+(step_size*current_index)), attendees_len );

    if(check==0){ 
        step_size = step_size+1;
        current_index = current_index-1;
    }
    return choose_random((current_index+1),winner_count, attendees_len, reference_point, step_size, winner_array);
}