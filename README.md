# Testnet
The version of our proof-of-concept solution to be deployed on the sepolia testnet.

## Requirements
You will need the following tools:

- [Node (v18 LTS)]
- Yarn ([v1] ```npm install --global yarn```)
  
## Getting started

1. Install dependencies
```
yarn install
```

2. Calculate your SystemManager address
Run the computeFutureAddress.py script and input your address and nonce

3. Place the address of your SystemManager in DigitalCopy contract

4. Create .env file
Create an .env file and input these variables with your own addresses:
```
ALCHEMY_API_KEY1=*YOUR_API_KEY*
ALCHEMY_URL='*YOUR_ALCHEMY_URL*'
PRIVATE_KEY1='*YOUR_FIRST_PRIVATE_KEY (Make sure it starts with 0x)*'
PRIVATE_KEY2='*YOUR_SECOND_PRIVATE_KEY (Make sure it starts with 0x)*'
```

5. Deploy the contracts in a terminal with the following command:
```
yarn deploy
```

6. Run the scenarios:
``` 
yarn scenario1-4 (E.g. scenario1)
```
