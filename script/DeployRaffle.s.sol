//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "../script/Interactions.s.sol";
contract DeployRaffle is Script {
    
    function run() external returns(Raffle,HelperConfig){
        
            Raffle raffle;
            HelperConfig helperConfig = new HelperConfig();
            (uint256 entranceFee, 
                uint256 interval,
                address vrfcoordinator, 
                bytes32 gasLane,
                uint64 subscriptionId,
                uint32 callbackGasLimit, address link,uint256 deployerKey)=helperConfig.activeNetworkConfig();
            
            //Creating the subscription if not already created

            if(subscriptionId==0){
                CreateSubscription createSubscription = new CreateSubscription();
                subscriptionId=createSubscription.createSubscription(vrfcoordinator,deployerKey);
                // Funding the subscription
                
            }
            FundSubscription fundSubscription= new FundSubscription();
                fundSubscription.fundSubscription(vrfcoordinator,subscriptionId,link,deployerKey);
            vm.startBroadcast();
            raffle = new Raffle(entranceFee,interval,vrfcoordinator,gasLane,subscriptionId,callbackGasLimit);
            vm.stopBroadcast();
            // Adding consumer
            AddConsumer addConsumer = new AddConsumer();
            addConsumer.addConsumer(vrfcoordinator,subscriptionId,address(raffle),deployerKey);
            return (raffle,helperConfig);
        }
        

}