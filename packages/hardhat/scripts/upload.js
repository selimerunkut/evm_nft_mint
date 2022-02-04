/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { utils } = require("ethers");
const R = require("ramda");
const ipfsAPI = require('ipfs-http-client');
const { exit } = require("process");
const ipfs = ipfsAPI({ host: 'ipfs.infura.io', port: '5001', protocol: 'https' })
global.__basedir = "/Users/selimerunkut/dev/portal_nft_project";


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


  const getAllDirFiles = function (dirPath, extension, arrayOfFiles) {
    files = fs.readdirSync(dirPath)

    arrayOfFiles = arrayOfFiles || []

    files.forEach(function (file) {
      if (file.split('.').pop() == extension) {
        arrayOfFiles.push(file)
      }
    })

    return arrayOfFiles
  }
  const jsonFileCount = getAllDirFiles(__basedir + "/scripts/privateassets", "json").length
  const imageFileCount = getAllDirFiles(__basedir + "/scripts/privateassets", "jpg").length



  console.log("jsonFileCount", jsonFileCount);
  console.log("imageFileCount", imageFileCount);



  let i = 0;
  while (i < imageFileCount) {
    if (i == currentIndex) {

      const file = fs.readFileSync(__basedir + "/scripts/privateassets/" + currentIndex + ".jpg")

      const uploadedImage = await ipfs.add(file)

      console.log("IPFS hash", uploadedImage.path)

      let currentJsonPath = __basedir + "/scripts/privateassets/" + currentIndex + ".json"
      let rawdata = fs.readFileSync(currentJsonPath);
      let item = JSON.parse(rawdata);
      const metadata = {
        "description": item.description,
        "external_url": "https://nftportal.io/",
        "image": uploadedImage.path,
        "name": item.name,
        "attributes": item.attributes,
      }

      console.log("Uploading manifest...")
      const uploaded = await ipfs.add(JSON.stringify(metadata))
      console.log("upload ok", uploaded)

      console.log("Update", currentIndex + ".json")
      fs.writeFileSync(currentJsonPath, JSON.stringify(metadata))

      currentIndex++;
      fs.writeFileSync(__basedir + "/currentIndex.txt", currentIndex.toString())
    }
    i++
  }

};



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
