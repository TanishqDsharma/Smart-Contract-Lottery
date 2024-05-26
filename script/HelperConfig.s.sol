//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
contract HelperConfig is Script{

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfcoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY =0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e;

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid==11155111){
             activeNetworkConfig = getSepoliaEthConfig();
        }else{
            activeNetworkConfig=getorCreateAnvilEthConfig();
        }

    }
    
    

    
    
    function getSepoliaEthConfig() public view returns(NetworkConfig memory)
    {
            return  NetworkConfig({
               entranceFee:0.01 ether,
               interval: 30,
               vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
               gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
               subscriptionId:1893,
               callbackGasLimit: 500000,
               link:0x779877A7B0D9E8603169DdbD7836e478b4624789 ,
               deployerKey: vm.envUint("PRIVATE_KEY")
            });

            

    }


    function getorCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.vrfcoordinator != address(0)){
            return activeNetworkConfig;
        }

        uint96 baseFee=0.25 ether; //0.25 LINK
        uint96 gasPriceLink=1e9; // 1 gwei LINK

        vm.startBroadcast();
        LinkToken linkToken = new LinkToken();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee,gasPriceLink);
        vm.stopBroadcast();

        return  NetworkConfig({
            entranceFee:0.01 ether,
            interval: 30,
            vrfcoordinator: address(vrfCoordinatorMock),
            gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId:0,
            callbackGasLimit: 500000,
            link: address(linkToken),
            deployerKey: DEFAULT_ANVIL_KEY
         });


    }




}