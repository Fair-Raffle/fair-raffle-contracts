// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStarknetCore.sol";

contract RaffleRandomClient is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    // For goerli testnet
    address starknetCoreContractAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    IStarknetCore starknet = IStarknetCore(starknetCoreContractAddress);
    uint256 l2ContractAddress;
    uint256 SELECTOR = 1088696223053132308773645305548840087074963352777964036583151858641713261517;


    struct RequestStatus {
        bool randomReturned; // if the callback is revoked by chainlik
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    mapping(uint256 => uint256) public raffleIdToRequestId;
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // for goerli-testnet
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 callbackGasLimit = 100000;

    // waits 3 blocks for confirmation
    uint16 requestConfirmations = 3;

    // Only one number is enough for our algorithm
    uint32 numWords = 1;

    // TEST
    bytes32 public lastHash;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;
    }

    function changeSelector (uint256 SELECTOR_) external onlyOwner {
        SELECTOR = SELECTOR_;
    }

    function changeL2ContractAddress (uint256 l2ContractAddress_) external onlyOwner {
        l2ContractAddress = l2ContractAddress_;
    }

    function changeStarknetCoreContract (address coreContract) external onlyOwner {
        starknetCoreContractAddress = coreContract;
        starknet = IStarknetCore(coreContract);
    }

    function initiateRaffle(uint256 raffleId) external {
        uint256[] memory payload = new uint256[](1);
        payload[0] = raffleId;
        // raffle maker cannot call it again as the message is consumed
        starknet.consumeMessageFromL2(l2ContractAddress, payload);
        requestRandomWords(raffleId);
    }

    function sendRandomToL2(uint256 raffleId) external {
        require(raffleIdToRequestId[raffleId] != 0, "Non existent or consumed raffle");
        uint256 reqId = raffleIdToRequestId[raffleId];
        require(s_requests[reqId].randomReturned == true, "No random words to send to l2");
        uint256[] memory randomWords = s_requests[reqId].randomWords;
        uint256[] memory payload = new uint256[](2);
        payload[0] = raffleId;
        payload[1] = randomWords[0];
        lastHash = starknet.sendMessageToL2(l2ContractAddress, SELECTOR, payload);
        raffleIdToRequestId[raffleId] = 0;
    }

    function sendRandomToL2Test(uint256 raffleId) external payable {
        uint256[] memory payload = new uint256[](2);
        payload[0] = raffleId;
        payload[1] = 111;
        lastHash = starknet.sendMessageToL2{value: msg.value}(l2ContractAddress, SELECTOR, payload);
    }



    function requestRandomWords(uint256 raffleId)
        private
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            randomReturned: false
        });
        raffleIdToRequestId[raffleId] = requestId;
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].randomReturned = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.randomReturned, request.randomWords);
    }
}
