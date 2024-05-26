//SPDX-License-Idnetifier: MIT

pragma solidity ^0.8.16;

import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
/**
 * @title Smart Contract Lottery
 * @author Tanishq Sharma
 * @notice This contract is creating a raffle
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    /**Type Declarations */
    enum RaffleState{
        Open,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS=3;
    uint32 private constant NUM_WORDS=1;


    
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfcoordinator;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;
    
    address payable[] public s_players;
    uint256 private  s_lastTimeStamp;
    RaffleState private s_raffleState;
    address private s_recentWinner;


    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(uint256 entranceFee,
                uint256 interval,
                address vrfcoordinator,
                bytes32 gasLane,
                uint64 subscriptionId,
                uint32 callbackGasLimit) VRFConsumerBaseV2(vrfcoordinator)
            {
                    i_entranceFee=entranceFee;
                    i_interval=interval;
                    s_lastTimeStamp=block.timestamp;
                    i_vrfcoordinator=VRFCoordinatorV2Interface(vrfcoordinator);
                    i_gasLane=gasLane;
                    i_subscriptionId=subscriptionId;
                    i_callbackGasLimit=callbackGasLimit;
                    s_raffleState= RaffleState.Open;
    }
    
    function enterRaffle() external payable{
        if(msg.value<i_entranceFee){
            revert Raffle__NotEnoughEthSent();
        }
        if(s_raffleState!=RaffleState.Open){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep(bytes memory /*checkData*/) public view returns(bool upkeepNeeded,bytes memory /*performData*/){
        bool timehaspassed = (block.timestamp-s_lastTimeStamp)>=i_interval;
        bool isOpen = RaffleState.Open == s_raffleState;
        bool hasBalance = address(this).balance>0;
        bool hasplayers = s_players.length>0;
        upkeepNeeded = (timehaspassed&&isOpen&&hasBalance&&hasplayers);
        return(upkeepNeeded,"0x0");
    }

    function perfromUpkeep(bytes memory /*checkData*/) external {        
        (bool upkeepNeeded,) = checkUpkeep("");
        if(!upkeepNeeded){
                revert Raffle__UpKeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
                }
        s_raffleState=RaffleState.CALCULATING;
       uint256 requestId = i_vrfcoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);

    }
    function fulfillRandomWords(uint256 /*requestId*/,uint256[] memory randomWords) internal override{
        uint256 indexofWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexofWinner];
        s_recentWinner=winner;
        s_raffleState= RaffleState.Open;
        (bool success,) = winner.call{value:address(this).balance}("");
        s_players= new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        if(!success){
            revert Raffle__TransferFailed();
            }
            emit PickedWinner(winner);
        
        }

    /** Getter Functions */

    function getEntranceFees() external view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getplayers(uint256 index) external view returns(address payable){
        return s_players[index];
    }
    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }

    function getPlayersLength() external view returns(uint256){
        return s_players.length;
    }

    function getLastTimestamp() external view returns(uint256){
        return s_lastTimeStamp;
    }
}