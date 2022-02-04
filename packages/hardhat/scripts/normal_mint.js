/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");
const ipfsAPI = require('ipfs-http-client');
const { exit } = require("process");
const ipfs = ipfsAPI({ host: 'ipfs.infura.io', port: '5001', protocol: 'https' })
global.__basedir = "/Users/selimerunkut/dev/scaffold-eth";



let currentIndex
try {
  currentIndex = parseInt(fs.readFileSync(__basedir + "/currentIndex.txt"))
  if (isNaN(currentIndex)) {
    currentIndex = 0
  }
} catch (e) {
  currentIndex = 0
}
console.log("read/set currentIndex:", currentIndex)

const main = async () => {
  //console.log(hre.network.config.url)
  //exit(1);

  //if (hre.network.name == 'rinkeby_nodeploy' || hre.network.name == 'testnet_nodeploy' || hre.network.name == 'hardhat') 

  const localProvider = new ethers.providers.StaticJsonRpcProvider(hre.network.config.url);

  let block = await localProvider.getBlockNumber()

  localProvider.resetEventsBlock(1);

  const { deployer } = await getNamedAccounts();
  console.log("deployer wallet: ", deployer)
  const yourCollectible = await ethers.getContract("YourCollectible", deployer);

  //await yourCollectible.togglePublicSale()
  //await yourCollectible.publicSaleMint(1, { value: ethers.utils.parseEther("0.001") })
  
  console.log("token uri: ", await yourCollectible.tokenURI(1))


};



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
