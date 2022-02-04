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


const delayMS = 1000 //sometimes xDAI needs a 6000ms break lol 😅

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

  let allEvents = await yourCollectible.queryFilter("Request")
  if (!allEvents.length) { console.log("No mint request events found") }


  for (let e in allEvents) {
    console.log("Checking index", e, "currentIndex", currentIndex)
    if (e == currentIndex) {
      console.log(allEvents[e].args.to + " is minting index " + currentIndex)

      const file = fs.readFileSync(__basedir + "/scripts/privateassets/" + currentIndex + ".jpg")

      const uploadedImage = await ipfs.add(file)

      console.log("IPFS hash", uploadedImage.path)

      let currentJsonPath = __basedir + "/scripts/privateassets/" + currentIndex + ".json"
      let rawdata = fs.readFileSync(currentJsonPath);
      let item = JSON.parse(rawdata);
      let baseUri = await yourCollectible.getBaseURI()
      const metadata = {
        "description": item.description,
        "external_url": "https://nftportal.io/",
        "image": uploadedImage.path,
        "name": item.name,
        "attributes": item.attributes,
      }

      console.log("Uploading manifest...")
      const uploaded = await ipfs.add(JSON.stringify(metadata))
      console.log("Update", currentIndex + ".json")
      fs.writeFileSync(currentJsonPath, JSON.stringify(metadata))

      console.log("image tokenUri will be", baseUri + uploadedImage.path)

      currentIndex++;
      fs.writeFileSync(__basedir + "/currentIndex.txt", currentIndex.toString())

      console.log("MINTING!!!", allEvents[e].args.to, uploaded.path)
      await yourCollectible.mintItem(allEvents[e].args.to, uploaded.path)
      let tokenUri = await yourCollectible.tokenURI(currentIndex)
      console.log("tokenURI after mint:", tokenUri)

    }

  }

};

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
