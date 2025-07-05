import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(await signer.getAddress());
  const address = await signer.getAddress();
  
  console.log("Account:", address);
  console.log("Balance (wei):", balance.toString());
  console.log("Balance (TEST):", ethers.formatEther(balance));
  
  // Get gas price
  const gasPrice = await ethers.provider.getFeeData();
  console.log("Current gas price (wei):", gasPrice.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 