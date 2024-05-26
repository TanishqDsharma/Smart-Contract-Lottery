
# Raffle - Made using Smart Contracts

## About:

Creating a SMART CONTRACT LOTTERY that will be using chainlink VRF to randomly select a winner and chainlink automation for automatically executing the lottery contract in certain time intervals.

## What we want it to do?

1. Users can enter by paying for a ticket
    1. Tickets fees will go to the winner after the draw
2. After X period of time the lottery will automatically draw a winner
    1. And this will be done programmatically
3. Using Chainlink VRF and Chainlink Automation 
    1. Chainlink VRF -> Randomness
    2. Chainlink Automation -> Will be a time based trigger for our lottery for our lottery to automatically trigger.

## Tests

1. Write Some Deploy Scripts
2. Write our tests so that they:
    1. Work on a local chain
    2. Forked Testnet
    3. Fored Mainnet