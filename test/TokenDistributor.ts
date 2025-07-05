import { ethers } from "hardhat";
import { expect } from "chai";

describe("TokenDistributor", function () {
  let TokenDistributor: any;
  let distributor: any;
  let owner: any, voiceTalent: any, protocol: any, user: any, other: any;
  let TestToken: any, testToken: any;

  beforeEach(async function () {
    [owner, voiceTalent, protocol, user, other] = await ethers.getSigners();

    // Deploy a test ERC20 token
    TestToken = await ethers.getContractFactory("TestToken", owner);
    testToken = await TestToken.deploy("TestToken", "TTK");
    await testToken.waitForDeployment();

    // Mint tokens to user
    await testToken.connect(owner).mint(user.address, ethers.parseEther("100"));

    // Deploy TokenDistributor with protocol.address as protocolAddress
    TokenDistributor = await ethers.getContractFactory("TokenDistributor", owner);
    distributor = await TokenDistributor.deploy(protocol.address);
    await distributor.waitForDeployment();
  });

  it("should distribute native tokens with 90/10 split", async function () {
    const amount = ethers.parseEther("1");
    const voiceTalentBalanceBefore = await ethers.provider.getBalance(voiceTalent.address);
    const protocolBalanceBefore = await ethers.provider.getBalance(protocol.address);

    // User sends native tokens with voiceTalent address as parameter
    await distributor.connect(user).distributeNativeTokens(
      voiceTalent.address, // voiceTalentAddress parameter
      ethers.ZeroHash, // confidentialId
      { value: amount }
    );

    const voiceTalentBalanceAfter = await ethers.provider.getBalance(voiceTalent.address);
    const protocolBalanceAfter = await ethers.provider.getBalance(protocol.address);

    expect(voiceTalentBalanceAfter - voiceTalentBalanceBefore).to.equal(amount * 90n / 100n);
    expect(protocolBalanceAfter - protocolBalanceBefore).to.equal(amount * 10n / 100n);
  });

  it("should distribute ERC20 tokens with 90/10 split", async function () {
    const amount = ethers.parseEther("10");
    // Ensure user has enough tokens before distribution
    await testToken.connect(owner).mint(user.address, amount);
    // User approves distributor
    await testToken.connect(user).approve(distributor.target, amount);
    // User calls distributeTokens with voiceTalent address as parameter
    await distributor.connect(user).distributeTokens(
      testToken.target,
      voiceTalent.address, // voiceTalentAddress parameter
      amount,
      ethers.ZeroHash
    );
    expect(await testToken.balanceOf(voiceTalent.address)).to.equal(amount * 90n / 100n);
    expect(await testToken.balanceOf(protocol.address)).to.equal(amount * 10n / 100n);
  });

  it("should only allow sender to view their distribution data", async function () {
    const amount = ethers.parseEther("1");
    // User sends native tokens with voiceTalent address as parameter
    const tx = await distributor.connect(user).distributeNativeTokens(
      voiceTalent.address, // voiceTalentAddress parameter
      ethers.ZeroHash,
      { value: amount }
    );
    const receipt = await tx.wait();
    const event = receipt.logs.find((log: any) => log.eventName === "TokensDistributed");
    const confidentialId = event.args.confidentialId;
    // User can view
    const data = await distributor.connect(user).getDistributionData(confidentialId);
    expect(data[0]).to.equal(user.address);
    // Other cannot view
    await expect(
      distributor.connect(other).getDistributionData(confidentialId)
    ).to.be.revertedWith("Access denied");
  });

  it("should emit TokensDistributed event", async function () {
    const amount = ethers.parseEther("1");
    await expect(
      distributor.connect(user).distributeNativeTokens(voiceTalent.address, ethers.ZeroHash, { value: amount })
    ).to.emit(distributor, "TokensDistributed");
  });
}); 