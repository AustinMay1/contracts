//  _________  ________  ___  __    ___  ________           ________  ___  ___  ________  _________  ________      
// |\___   ___\\   __  \|\  \|\  \ |\  \|\   ___  \        |\   ____\|\  \|\  \|\   __  \|\___   ___\\   ____\     
// \|___ \  \_\ \  \|\  \ \  \/  /|\ \  \ \  \\ \  \       \ \  \___|\ \  \\\  \ \  \|\  \|___ \  \_\ \  \___|_    
//      \ \  \ \ \   __  \ \   ___  \ \  \ \  \\ \  \       \ \_____  \ \   __  \ \  \\\  \   \ \  \ \ \_____  \   
//       \ \  \ \ \  \ \  \ \  \\ \  \ \  \ \  \\ \  \       \|____|\  \ \  \ \  \ \  \\\  \   \ \  \ \|____|\  \  
//        \ \__\ \ \__\ \__\ \__\\ \__\ \__\ \__\\ \__\        ____\_\  \ \__\ \__\ \_______\   \ \__\  ____\_\  \ 
//         \|__|  \|__|\|__|\|__| \|__|\|__|\|__| \|__|       |\_________\|__|\|__|\|_______|    \|__| |\_________\
//                                                            \|_________|                             \|_________|

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract TakinShots is ERC721, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /// @dev maximum supply of NFT's & max mint
    uint256 maxSupply = 444;
    uint public maxMintPerAddress = 1;

    /// @todo auto open mint windows
    /// @dev 1 hour window for ogMint
    bool public ogMintOpen = false;

    /// @dev 48 hour window for whiteListMint
    bool public whiteListMintOpen = false;

    /// @dev enable allowListMint if whiteListMint is not completed in 48 hours
    bool public allowListMintOpen = false;

    /// @dev reveal functionality
    bool private revealed = false;
    string private revealURL = "https://someURL.eth/{cid}/notRevealed.json";

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(revealed == true) {
            return super.tokenURI(tokenId);
        } else {
            return revealURL;
        }
    }

    function revealCollection() public {
        revealed = true;
    }
    
    // address lists for each phase
    /// @todo implement merkle trees for og, wl, al
    mapping(address => bool) public ogList;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public allowList;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("TakinShots", "TS") {}

    /// @todo upload art to ipfs/pinata
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://{cid}";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev modify mint windows
    function mintWindows(bool _allowListMintOpen, bool _ogMintOpen, bool _whiteListMintOpen) external onlyOwner {
            ogMintOpen = _ogMintOpen;
            whiteListMintOpen = _whiteListMintOpen;
            allowListMintOpen = _allowListMintOpen;
    }

    function ogMint() public payable {
        require(ogMintOpen, "OG Mint has ended.");
        require(ogList[msg.sender], "Sorry, you are not OG.");
        mint();
    }

    function whiteListMint() public payable {
        require(whiteListMintOpen, "Whitelist mint has ended.");
        require(whiteList[msg.sender], "Sorry, you are not whitelisted.");
        mint();
    }

    function allowMint() public payable {
        require(allowListMintOpen, "Try again later.");
        require(allowList[msg.sender], "Sorry, you are not allowedlisted");
        mint();
    }

    /// @dev add address to the og list.
    function setOgList(address[] calldata _ogList) external onlyOwner {
        for(uint256 i = 0; i < _ogList.length; i++) {
            ogList[_ogList[i]] = true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev keep some Takin Shots NFT's for team/giveaways
    /// @todo implement functionality to auto-mint x amount for team

    /// @dev mint functionality
    function mint() internal {
            require(msg.value == 0 ether);
            require(totalSupply() < maxSupply, "Sale has ended.");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
    }

    /// @dev withdraw funds from contract. this particular mint is free.
    function withdraw(address _addr) external onlyOwner {
        //get balance
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    /// @todo clean up code, test, hook to frontend.
}