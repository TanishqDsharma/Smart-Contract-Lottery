//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script,console} from "../lib/forge-std/src/Script.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{

    function createSubscriptionUsingConfig() public returns(uint64){
        HelperConfig helperConfig = new HelperConfig();
        (, ,address vrfcoordinator, , ,,,uint256 deployerKey)=helperConfig.activeNetworkConfig();
        return createSubscription(vrfcoordinator,deployerKey);
    }
    
    function createSubscription(address vrfcoordinator,uint256 deployerKey) public returns(uint64){
        console.log("Creating Subscription on ChainId: ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId=VRFCoordinatorV2Mock(vrfcoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription is:",subId);
        console.log("Please update subId in HelperConfig.s.sol");

        return subId;
    }
    
    function run() external returns(uint64){
        return createSubscriptionUsingConfig();
    }
}


contract FundSubscription is Script{
uint96 public constant FUND_AMOUNT = 3 ether;
function fundSubscriptionUsingConfig() public {
    HelperConfig helperConfig = new HelperConfig();
    (, ,address vrfcoordinator, ,uint64 subscriptionId,,address link,uint256 deployerKey)=helperConfig.activeNetworkConfig();
     fundSubscription(vrfcoordinator,subscriptionId,link,deployerKey);
}

function fundSubscription(address vrfcoordinator,uint64 subscriptionId, address link,uint256 deployerKey) public{

    console.log("Funding Subscription: ", subscriptionId);
    console.log("Using vrfcoordinator: ", vrfcoordinator);
    console.log("On ChainID: ", block.chainid);

    if(block.chainid==31337){
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfcoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
        vm.stopBroadcast();
    }else{
        LinkToken(link).transferAndCall(vrfcoordinator,FUND_AMOUNT,abi.encode(subscriptionId));
    }
    
}
function run() external{
     fundSubscriptionUsingConfig();

}

}

contract AddConsumer is Script{

    function run() external {
        address raffleContractAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffleContractAddress);
    }

    function addConsumerUsingConfig(address raffleContractAddress) public {
        HelperConfig helperConfig = new HelperConfig();
        (, ,address vrfcoordinator, ,uint64 subscriptionId,,,uint256 deployerKey)=helperConfig.activeNetworkConfig();        
        addConsumer(vrfcoordinator,subscriptionId,raffleContractAddress,deployerKey);

    }

    function addConsumer(address vrfcoordinator,uint64 subscriptionId, address raffleContractAddress,uint256 deployerKey) public {
        console.log("Adding Consumer Contract: ", raffleContractAddress);
        console.log("Using subscriptionId: ", subscriptionId);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfcoordinator).addConsumer(subscriptionId, raffleContractAddress);
        vm.stopBroadcast();
    }
}