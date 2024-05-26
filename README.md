
# Raffle - SMART CONTRACT

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
    3. Forked Mainnet
  
# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/Cyfrin/foundry-smart-contract-lottery-f23
cd foundry-smart-contract-lottery-f23
forge build
```

# Usage

## Start a local node

```
make anvil
```

## Library

If you're having a hard time installing the chainlink library, you can optionally run this command. 

```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
make deploy
```
