// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract YourCollectible is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public root;

    address proxyRegistryAddress;

    string BASE_URI = "https://ipfs.io/ipfs/";

    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;

    uint256 constant TOTAL_SUPPLY = 8888;
    uint256 constant INCREASED_MAX_TOKEN_ID = TOTAL_SUPPLY + 2;
    uint256 constant MINT_PRICE = 0.001 ether;

    uint256 constant NUMBER_OF_TOKENS_ALLOWED_PER_TX = 10;
    uint256 constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 20;

    mapping(address => uint256) addressToMintCount;

    address FOUNDER_1 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address FOUNDER_2 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TECH_LEAD = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address COMMUNITY_WALLET = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_1 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_2 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_3 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_4 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_5 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_6 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_7 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_8 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_9 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_10 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;
    address TEAM_11 = 0x7922c8e147b4d3BBd593D884D973c1ed7ab88B3f;

    event publicSaleMintEvent(uint256 numberOfTokens, string tokenUri);

    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleroot,
        address _proxyRegistryAddress
    ) ERC721(name, symbol) {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;
        _tokenIdCounter.increment();
    }

    /// @inheritdoc ERC721URIStorage
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    // TODO add public burn function (only NFT owner can burn the NFT)
    //  ERC721 function ownerOf can be used

    /// @inheritdoc ERC721URIStorage
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        ERC721URIStorage._burn(tokenId);
    }

    function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
        root = merkleroot;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory newUri) public onlyOwner {
        BASE_URI = newUri;
    }

    function togglePublicSale() public onlyOwner {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function togglePreSale() public onlyOwner {
        IS_PRESALE_ACTIVE = !IS_PRESALE_ACTIVE;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function ownerMint(uint256 numberOfTokens, string memory tokenUri) public onlyOwner {
        uint256 current = _tokenIdCounter.current();
        require(
            current + numberOfTokens < INCREASED_MAX_TOKEN_ID,
            "Exceeds total supply"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintInternal(tokenUri);
        }
    }

    function presaleMint(
        address account,
        uint256 numberOfTokens,
        uint256 allowance,
        string memory key,
        bytes32[] calldata proof,
        string memory tokenUri
    ) public payable onlyAccounts {
        require(msg.sender == account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre-sale haven't started");
        require(
            msg.value >= numberOfTokens * MINT_PRICE,
            "Not enough ethers sent"
        );

        string memory payload = string(
            abi.encodePacked(Strings.toString(allowance), ":", key)
        );

        require(
            _verify(_leaf(msg.sender, payload), proof),
            "Invalid merkle proof"
        );

        uint256 current = _tokenIdCounter.current();

        require(
            current + numberOfTokens < INCREASED_MAX_TOKEN_ID,
            "Exceeds total supply"
        );
        require(
            addressToMintCount[msg.sender] + numberOfTokens <= allowance,
            "Exceeds allowance"
        );

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintInternal(tokenUri);
        }
    }

    function publicSaleMint(uint256 numberOfTokens, string memory tokenUri)
        public
        payable
        onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(
            numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_TX,
            "Too many requested"
        );
        require(
            msg.value >= numberOfTokens * MINT_PRICE,
            "Not enough ethers sent"
        );

        uint256 current = _tokenIdCounter.current();

        require(
            current + numberOfTokens < INCREASED_MAX_TOKEN_ID,
            "Exceeds total supply"
        );
        require(
            addressToMintCount[msg.sender] + numberOfTokens <=
                NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS,
            "Exceeds allowance"
        );

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintInternal(tokenUri);
        }
        emit publicSaleMintEvent(numberOfTokens, tokenUri);

    }

    function getCurrentMintCount(address _account)
        public
        view
        returns (uint256)
    {
        return addressToMintCount[_account];
    }

    function _mintInternal(string memory tokenUri) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenUri);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(FOUNDER_1, (balance * 230) / 1000);
        _withdraw(FOUNDER_2, (balance * 230) / 1000);
        _withdraw(TECH_LEAD, (balance * 50) / 1000);
        _withdraw(COMMUNITY_WALLET, (balance * 200) / 1000);
        _withdraw(TEAM_1, (balance * 80) / 1000);
        _withdraw(TEAM_2, (balance * 65) / 1000);
        _withdraw(TEAM_3, (balance * 50) / 1000);
        _withdraw(TEAM_4, (balance * 20) / 1000);
        _withdraw(TEAM_5, (balance * 15) / 1000);
        _withdraw(TEAM_6, (balance * 15) / 1000);
        _withdraw(TEAM_7, (balance * 10) / 1000);
        _withdraw(TEAM_8, (balance * 10) / 1000);
        _withdraw(TEAM_9, (balance * 10) / 1000);
        _withdraw(TEAM_10, (balance * 10) / 1000);
        _withdraw(TEAM_11, (balance * 5) / 1000);

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(
        address _owner,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _leaf(address account, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
