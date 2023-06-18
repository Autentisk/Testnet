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

    // Setting up the buyer
    const buyersDigitalCopy = new ethers.Contract(contractAddresses.digitalCopy, DigitalCopyArtifact.abi, account2);;
    const buyersUsers = new ethers.Contract(contractAddresses.users, UsersArtifact.abi, account2);

    try {
        await buyersUsers.createUser("Ola Hermansen", "12121992-60009")
    } catch (error) {
        if (typeof error === 'object' && error !== null && 'reason' in error) {
            const err = error as { reason: string };
            console.log('Revert reason:', err.reason);
        } else {
            console.error(error);
        }
    }

    // Buyer tries to get information about an item not for sale
    console.log (await digitalCopy.getOwner(0));
    console.log( await buyersDigitalCopy.isItemForSale(0));
    try {
        console.log (await buyersDigitalCopy.retrieveInformationForDigitalCopy(0));
    } catch (error) {
        if (typeof error === 'object' && error !== null && 'reason' in error) {
            const err = error as { reason: string };
            console.log('Revert reason:', err.reason);
        } else {
            console.error(error);
        }
    }
    
    // Seller puts the item for sale, now the buyer can access it
    await digitalCopy.putItemForSale(0);
    console.log (await buyersDigitalCopy.retrieveInformationForDigitalCopy(0));
    console.log( await buyersDigitalCopy.isItemForSale(0));

    // The seller makes the sale and transfers the NFT to the buyer
    await digitalCopy.transfer(0, account2.address, "450 000");
    console.log (await digitalCopy.getOwner(0));

    // The seller tries to sell item back the themself cheaper
    await digitalCopy.putItemForSale(0);
    await digitalCopy.transfer(0, account1.address, "350 000");
}
main().catch(e => {
    console.error(e);
    process.exit(1);
});