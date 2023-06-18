import { ethers, ContractFactory, Contract } from 'ethers';
let SystemManagerArtifact = require('artifacts/contracts/SystemManager.sol/SystemManager.json');
let TrustedSellerArtifact = require('artifacts/contracts/TrustedSeller.sol/TrustedSeller.json');
let DigitalCopyArtifact = require('artifacts/contracts/DigitalCopy.sol/DigitalCopy.json');
import dotenv from 'dotenv';
import * as fs from 'fs';

dotenv.config();

async function main() {

    // Setting up the environment
    if (!process.env.PRIVATE_KEY1 || !process.env.PRIVATE_KEY2) {
        throw new Error("Private keys are not set in the environment variables.");
    }

    const provider = new ethers.providers.JsonRpcProvider(process.env.ALCHEMY_API_KEY1);
    const account1 = new ethers.Wallet(process.env.PRIVATE_KEY1, provider);
    const account2 = new ethers.Wallet(process.env.PRIVATE_KEY2, provider);

    let systemManager: Contract;
    let trustedSeller: Contract;
    let digitalCopy: Contract;

    // Deploy SystemManager with Users and Reviews

    const SystemManagerFactory: ContractFactory = new ethers.ContractFactory(SystemManagerArtifact.abi, SystemManagerArtifact.bytecode, account1);
    let usersAddress: string | null = null;
    let reviewsAddress: string | null = null;

    let UsersEvent: Promise <void> = new Promise((resolve, reject) => {
        systemManager.once("DeployedUsersContract", (address) => {
            usersAddress = address;
            console.log("Users.sol contract deployed to address:", address)
            resolve();
        });

    });

    let ReviewsEvent: Promise <void> = new Promise((resolve, reject) => {
        systemManager.once("DeployedReviewsContract", (address) => {
            reviewsAddress = address;
            console.log("Reviews.sol contract deployed to address:", address);
            resolve();
        });
    });

    systemManager = await SystemManagerFactory.deploy();
    await UsersEvent;
    await ReviewsEvent;
    await systemManager.deployed();

    console.log("SystemManager.sol contract deployed to address: ", systemManager.address);

    // Deploy DigitalCopy
    let digitalCopyAddress: string | null = "";
    let DigialCopyEvent: Promise <void> = new Promise((resolve, reject) => {
        systemManager.on("DeployedDigitalCopyContract", (address) => {
            digitalCopyAddress = address;
            console.log("DigitalCopy.sol contract deployed to address:", address);
            resolve();
        });
    });

    await systemManager.deployDigitalCopy();
    await DigialCopyEvent;
    digitalCopy = new ethers.Contract(digitalCopyAddress, DigitalCopyArtifact.abi, account1);

    // Deploy TrustedSeller.sol
    const TrustedSellerFactory: ContractFactory = new ethers.ContractFactory(TrustedSellerArtifact.abi, TrustedSellerArtifact.bytecode, account1);
    trustedSeller = await TrustedSellerFactory.deploy("TrustedWatches", systemManager.address);
    await trustedSeller.deployed();
    console.log("TrustedSeller.sol contract deployed to address: ", trustedSeller.address);

    // Add Trusted Seller to the approved list
    await systemManager.add(trustedSeller.address);

    // Set Trusted Sellers' DigitalCopy contract to interact with
    await trustedSeller.changeDigitalCopyContract(digitalCopyAddress);

    // Write variables to file
    let contractAddresses = {
        systemManager: systemManager.address,
        trustedSeller: trustedSeller.address,
        digitalCopy: digitalCopyAddress,
        users: usersAddress,
        reviews: reviewsAddress
    };

    fs.writeFileSync('scripts/contractAddresses.json', JSON.stringify(contractAddresses, null, 2));
    process.exit(0);
}

main().catch(e => {
    console.error(e);
    process.exit(1);
});
