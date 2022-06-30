// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address, address, uint) external;
}

contract Auction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    uint public nftId;
    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    constructor(address _nft, uint _nftId, uint _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        require(!started, "AUCTION STARTED");
        require(msg.sender == seller, "NOT SELLER");
        started = true;
        emit Start();
    }

    function bid() external payable {
        require(started, "AUCTION NOT STARTED");
        require(msg.value > highestBid, "VALUE < HIGHEST");

        if(highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        require(ended, "AUCTION NOT ENDED");
        require(msg.sender != highestBidder, "YOU ARE THE WINNER OF AUCTION, CANNOT WITHDRAW");
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "AUCTION NOT STARTED");
        require(msg.sender == seller, "NOT SELLER");
        require(!ended, "AUCTION ENDED");

        ended = true;
        if(highestBidder != address(0)) {
            nft.safeTransferFrom(seller, highestBidder, nftId);
            seller.transfer(highestBid);
        }

        

        emit End(highestBidder, highestBid);
    }
}
