// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/ERC721/extensions/ERC721Enumerable.sol";
import "./access/Ownable.sol";
import "./utils/Strings.sol";

contract BigMouth is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 1000;
    
    uint256 public mintPrice = 0.1 ether;
    uint256 public maxBalance = 1;
    uint256 public maxMint = 1;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;

    // Whitelist
    mapping(address => bool) public whitelist;
    uint256 public whitelistMaxSupply = 100;
    bool public _isWhitelistSaleActive = false;
    uint256 public mintPriceWhitelist = 0.01 ether;

    constructor(string memory initBaseURI, string memory initNotRevealedUri)
        ERC721("Big Mouth", "BM")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    // 白名单铸造
    function whitelistMint(uint256 tokenQuantity) public payable {
        // 白名单相关检查
        require(whitelist[msg.sender], "Not in whitelist");
        require(_isWhitelistSaleActive, "Whitelist Sale must be active to mint BigMouths");
        require(
            totalSupply() + tokenQuantity <= whitelistMaxSupply,
            "Sale would exceed whitelist max supply"
        );
        
        // 通用检查
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            tokenQuantity * mintPriceWhitelist <= msg.value,
            "Not enough ether sent"
        );
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");

        _mintBigMouth(tokenQuantity);
    }

    // 批量新增 白名单地址
    function batchAddToWhitelist(address[] memory _newEntry) external onlyOwner {
        // 每次最多批量添加200个白名单，参数是一个地址的数组 ["0x...","0x...","0x..."]
        require(_newEntry.length <= 200,"to is more than 200");
        for (uint8 i = 0; i < _newEntry.length; i++) {
			whitelist[_newEntry[i]] = true;
		}
    }

    // 移除 白名单地址
    function removeFromWhitelist(address _newEntry) external onlyOwner {
        require(whitelist[_newEntry], "Previous not in whitelist");
        whitelist[_newEntry] = false;
    }

    // 检查某个地址是否在白名单中，true在，false不在
    function isAddressWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    // 普通铸造
    function mintBigMouth(uint256 tokenQuantity) public payable {
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(_isSaleActive, "Sale must be active to mint BigMouths");
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");

        _mintBigMouth(tokenQuantity);
    }

    function _mintBigMouth(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function flipWhitelistSaleActive() public onlyOwner {
        _isWhitelistSaleActive = !_isWhitelistSaleActive;
    }

    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function setWhitelistMaxSupply(uint256 _whitelistMaxSupply) public onlyOwner {
        whitelistMaxSupply = _whitelistMaxSupply;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}