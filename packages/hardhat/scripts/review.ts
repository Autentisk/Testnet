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
    const buyersReviews = new ethers.Contract(contractAddresses.reviews, ReviewsArtifact.abi, account2);

    // Trying to make a review for wrong item
    try {
        console.log(account1.address, digitalCopy.address);
        await buyersReviews.newReview(account1.address, 4, digitalCopy.address, 1, 
            "0x74657374537472696e6720746f20636f6e7665727420746f2062797465733332", "Nice watch and good communication with seller!");
    } catch (error) {
        if (typeof error === 'object' && error !== null && 'reason' in error) {
            const err = error as { reason: string };
            console.log('Revert reason:', err.reason);
        } else {
            console.error(error);
        }
    }

    // Making the review for the right item
    await buyersReviews.newReview(account1.address, 4, digitalCopy.address, 0, 
        "0x74657374537472696e6720746f20636f6e7665727420746f2062797465736932", "Nice watch and good communication with seller!");
    
    // Verifying the review on the seller
    await digitalCopy.putItemForSale(1);
    console.log(await systemManager.retrieveListingInformation(digitalCopy.address, 1));


}
main().catch(e => {
    console.error(e);
    process.exit(1);
});