//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Test,console} from "../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";



contract RaffleTest is Test{

event EnteredRaffle(address indexed player);

Raffle raffle;
HelperConfig helperConfig;

address public Player = makeAddr("player");
uint256 public constant STARTING_USER_BALNCE = 10 ether;

uint256 entranceFee; 
uint256 interval;
address vrfcoordinator; 
bytes32 gasLane;
uint64 subscriptionId;
uint32 callbackGasLimit;
address link;

function setUp() external{
    DeployRaffle deployRaffle = new DeployRaffle();
    (raffle,helperConfig) = deployRaffle.run();
    (entranceFee, 
    interval,
    vrfcoordinator, 
    gasLane,
    subscriptionId,
    callbackGasLimit,link,)=helperConfig.activeNetworkConfig();
        vm.deal(Player,STARTING_USER_BALNCE);

}


function testRaffleInitializesInOpenState() public view {

    assert(raffle.getRaffleState()==Raffle.RaffleState.Open);

}

function testEnterRaffleEntranceFee() public  {

    vm.prank(Player);
    vm.expectRevert();
    raffle.enterRaffle{value:0.001 ether}();


}

function testRaffleRecordsPlayerWhentheyEnter() public {
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    address payable player = raffle.getplayers(0);
    assert(player!=address(0));
}

function testEmitsEventsOnEntrance() public{
    vm.prank(Player);

    // Act / Assert
    vm.expectEmit(true, false, false, false, address(raffle));
    emit EnteredRaffle(Player);
    raffle.enterRaffle{value: entranceFee}();
}

function testCantEnterWhenRaffleisCalculating() public{
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp+interval+1);
    vm.roll(block.number+1);
    raffle.perfromUpkeep("");
    vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();

}

////////////////////
////////checkupKeep/
/////////////////// 

function testCheckUpKeepretrunsFalseIfitHasNoBalance() public {
    vm.warp(block.timestamp+interval);
    vm.roll(block.number+1);
    
    (bool upkeepNeeded,) = raffle.checkUpkeep("");
    
    assert(upkeepNeeded==false);


}

function testCheckUpKeepretrunsFalseIfRaffleIsNotOpen() public {
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp+interval+1);
    vm.roll(block.number+1);
    raffle.perfromUpkeep("");
    (bool upkeepNeeded,)=raffle.checkUpkeep("");
    assert(upkeepNeeded==false);
    console.log(msg.sender);
    console.log(address(this));
}

function testCheckUpKeepretrunsFalseIfEnoughTimeHasntPassed() public {
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    (bool upkeepNeeded,) = raffle.checkUpkeep("");
    assert(upkeepNeeded==false);

}

function testCheckUpKeepretrunsTrueifParametersaregood() public {
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp+interval+1);
    vm.roll(block.number+1);
    (bool upkeepNeeded,) = raffle.checkUpkeep("");
    assert(upkeepNeeded==true);
}

///////////////////
///PerformUpKeep///
///////////////////

function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {

    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp+interval+1);
    vm.roll(block.number+1);
    (bool upkeepNeeded,) = raffle.checkUpkeep("");
    assert(upkeepNeeded==true);
    raffle.perfromUpkeep("");


}
function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsFalse() public {

    vm.prank(Player);
    vm.warp(block.timestamp+interval+1);
    vm.roll(block.number+1);
    (bool upkeepNeeded,) = raffle.checkUpkeep("");
    vm.expectRevert();
    raffle.perfromUpkeep("");


}
modifier raffleEnteredandTimePassed(){
    vm.prank(Player);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp+interval+1);
    vm.roll(block.number+1);
    _;
}

function testPerfromUpkeepUpdatesRaffleStateandEmitRequestId() public raffleEnteredandTimePassed{
    vm.recordLogs();
    raffle.perfromUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];
    Raffle.RaffleState rstate = raffle.getRaffleState();
    assert(uint256(requestId)>0);
    assert(uint256(rstate)==1);
}




////////////////////////////////
//// FullFillRandomWords//////// 
////////////////////////////////

modifier skipFork(){
    if(block.chainid!=31337){
        return;
    }else{
        _;
    }
}

function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId) public raffleEnteredandTimePassed skipFork{
    
    vm.expectRevert();
    VRFCoordinatorV2Mock(vrfcoordinator).fulfillRandomWords(randomRequestId, address(raffle));

}


function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEnteredandTimePassed skipFork
        
    {
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimestamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.perfromUpkeep("");// emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        VRFCoordinatorV2Mock(vrfcoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimestamp();
        uint256 prize = entranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }

}