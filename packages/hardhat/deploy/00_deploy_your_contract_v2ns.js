// deploy/00_deploy_your_contract.js
const { parseEther } = require('ethers/lib/utils');


module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress = "0x0000000000000000000000000000000000000000";
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else if (network === 'live') {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }
  let merkleRoot = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
  await deploy("YourCollectible", {
    from: deployer,
    args: ["Portal Collectible NFT", "PCN", merkleRoot, proxyRegistryAddress],
    log: true,
  });


  // Getting a previously deployed contract
  //const YourCollectible = await ethers.getContract("YourCollectible", deployer);
  //await YourCollectible.setRoyalties("0x5f0eD8a432e4472936a889A0e1F97cb8e63dAAD9", 250);
};
module.exports.tags = ["YourCollectible"];
