import { ethers, ContractFactory, Contract } from 'ethers';
let SystemManagerArtifact = require('artifacts/contracts/SystemManager.sol/SystemManager.json');
let TrustedSellerArtifact = require('artifacts/contracts/TrustedSeller.sol/TrustedSeller.json');
let DigitalCopyArtifact = require('artifacts/contracts/DigitalCopy.sol/DigitalCopy.json');
let UsersArtifact = require('artifacts/contracts/Users.sol/Users.json');
let ReviewsArtifact = require('artifacts/contracts/Reviews.sol/Reviews.json');
import dotenv from 'dotenv';
const contractAddresses = require('./contractAddresses.json');

dotenv.config();

async function main() {

    // Setting up the environment
    if (!process.env.PRIVATE_KEY1 || !process.env.PRIVATE_KEY2) {
        throw new Error("Private keys are not set in the environment variables.");
    }

    const provider = new ethers.providers.JsonRpcProvider(process.env.ALCHEMY_API_KEY1);
    const account1 = new ethers.Wallet(process.env.PRIVATE_KEY1, provider);
    const account2 = new ethers.Wallet(process.env.PRIVATE_KEY2, provider);

    // Setting up the first user
    const systemManager = new ethers.Contract(contractAddresses.systemManager, SystemManagerArtifact.abi, account1);
    const trustedSeller = new ethers.Contract(contractAddresses.trustedSeller, TrustedSellerArtifact.abi, account1);
    const digitalCopy = new ethers.Contract(contractAddresses.digitalCopy, DigitalCopyArtifact.abi, account1);
    const users = new ethers.Contract(contractAddresses.users, UsersArtifact.abi, account1);
    const reviews = new ethers.Contract(contractAddresses.reviews, ReviewsArtifact.abi, account1);

    // Trying to burn the wrong NFT
    try {
        await digitalCopy.burn(0);
    } catch (error) {
        if (typeof error === 'object' && error !== null && 'reason' in error) {
            const err = error as { reason: string };
            console.log('Revert reason:', err.reason);
        } else {
            console.error(error);
        }
    }

    // Burning the right NFT
    console.log( await systemManager.retrieveAllOwnedItems(account1.address));
    await digitalCopy.burn(1);
    console.log( await systemManager.retrieveAllOwnedItems(account1.address));
}

main().catch(e => {
    console.error(e);
    process.exit(1);
});