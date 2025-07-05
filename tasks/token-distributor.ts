import { task } from "hardhat/config";

task("deploy-token-distributor")
  .addParam("protocol", "Protocol address")
  .setAction(async (args, hre) => {
    const TokenDistributor = await hre.ethers.getContractFactory("TokenDistributor");
    const distributor = await TokenDistributor.deploy(args.protocol);
    const distributorAddr = await distributor.waitForDeployment();

    console.log(`TokenDistributor deployed to: ${distributorAddr.target}`);
    console.log(`Protocol Address: ${args.protocol}`);
    
    return distributorAddr.target;
  });

task("distribute-tokens")
  .addParam("address", "TokenDistributor contract address")
  .addParam("token", "ERC20 token address")
  .addParam("voiceTalent", "Voice talent address")
  .addParam("amount", "Amount to distribute")
  .addOptionalParam("confidentialId", "Optional confidential ID")
  .setAction(async (args, hre) => {
    const distributor = await hre.ethers.getContractAt("TokenDistributor", args.address);
    
    // First approve the distributor to spend tokens
    const token = await hre.ethers.getContractAt("ERC20", args.token);
    const approveTx = await token.approve(args.address, args.amount);
    await approveTx.wait();
    console.log(`Approved ${args.amount} tokens for distribution`);
    
    // Distribute tokens
    const confidentialId = args.confidentialId || "0x0000000000000000000000000000000000000000000000000000000000000000";
    const tx = await distributor.distributeTokens(args.token, args.voiceTalent, args.amount, confidentialId);
    console.log(`Distribution transaction: ${tx.hash}`);
    await tx.wait();
    console.log("Distribution completed!");
  });

task("distribute-native")
  .addParam("address", "TokenDistributor contract address")
  .addParam("voiceTalent", "Voice talent address")
  .addParam("amount", "Amount in ROSE to distribute")
  .addOptionalParam("confidentialId", "Optional confidential ID")
  .setAction(async (args, hre) => {
    const distributor = await hre.ethers.getContractAt("TokenDistributor", args.address);
    
    const confidentialId = args.confidentialId || "0x0000000000000000000000000000000000000000000000000000000000000000";
    const tx = await distributor.distributeNativeTokens(args.voiceTalent, confidentialId, { value: args.amount });
    console.log(`Native distribution transaction: ${tx.hash}`);
    await tx.wait();
    console.log("Native distribution completed!");
  });

task("get-distribution-data")
  .addParam("address", "TokenDistributor contract address")
  .addParam("confidentialId", "Confidential ID")
  .setAction(async (args, hre) => {
    const distributor = await hre.ethers.getContractAt("TokenDistributor", args.address);
    
    try {
      const data = await distributor.getDistributionData(args.confidentialId);
      console.log("Distribution Data:");
      console.log(`Sender: ${data[0]}`);
      console.log(`Amount: ${data[1]}`);
      console.log(`Timestamp: ${data[2]}`);
    } catch (error: any) {
      console.log("Error:", error.message);
    }
  });

task("get-my-distributions")
  .addParam("address", "TokenDistributor contract address")
  .setAction(async (args, hre) => {
    const distributor = await hre.ethers.getContractAt("TokenDistributor", args.address);
    
    try {
      const ids = await distributor.getMyDistributionIds();
      console.log("Your distribution IDs:");
      ids.forEach((id: string, index: number) => {
        console.log(`${index + 1}. ${id}`);
      });
    } catch (error: any) {
      console.log("Error:", error.message);
    }
  });

task("get-total-distributions")
  .addParam("address", "TokenDistributor contract address")
  .setAction(async (args, hre) => {
    const distributor = await hre.ethers.getContractAt("TokenDistributor", args.address);
    
    const total = await distributor.getTotalDistributions();
    console.log(`Total distributions: ${total}`);
  });

task("full-token-distribution")
  .addParam("voiceTalent", "Voice talent address")
  .addParam("protocol", "Protocol address")
  .addParam("token", "ERC20 token address")
  .addParam("amount", "Amount to distribute")
  .setAction(async (args, hre) => {
    await hre.run("compile");

    console.log("Deploying TokenDistributor...");
    const address = await hre.run("deploy-token-distributor", { protocol: args.protocol });

    console.log("Distributing tokens...");
    await hre.run("distribute-tokens", { 
      address, 
      token: args.token,
      voiceTalent: args.voiceTalent,
      amount: args.amount 
    });

    console.log("Getting distribution info...");
    await hre.run("get-total-distributions", { address });
  }); 