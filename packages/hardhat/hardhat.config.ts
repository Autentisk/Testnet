import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@typechain/ethers-v5'
import "hardhat-deploy";
import '@nomiclabs/hardhat-ethers';
import dotenv from 'dotenv';

dotenv.config();
// const providerApiKey = process.env.ALCHEMY_API_KEY || "oKxs-03sij-U_N0iOlrSsZFr29-IqbuF";

// Can also be stored here
const { ALCHEMY_API_KEY1, PRIVATE_KEY1 } = process.env;

if (!ALCHEMY_API_KEY1 || !PRIVATE_KEY1) {
  console.error("Please set your environment variables in a .env file or your environment");
  process.exit(1);
}

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  defaultNetwork: "localhost",
  namedAccounts: {
    deployer: {
      // By default, it will take the first Hardhat account as the deployer
      default: 0,
    }
  },
  networks: {
    hardhat: {},
    sepolia: {
      url: `https://eth-sepolia.alchemyapi.io/v2/${ALCHEMY_API_KEY1}`,
      accounts: [PRIVATE_KEY1],
    }
  }
};

const { ALCHEMY_API_KEY, PRIVATE_KEY } = process.env;

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
};

export default config;