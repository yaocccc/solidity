pragma solidity ^0.8.1;

contract Auction {
    address public beneficiary;
    uint public auctionEndTime;   // 结束时间戳

    address public highestBidder; // 当前最高出价人
    uint public highestBid;       // 当前最高出价

    bool ended;

    mapping(address => uint) pendingReturns;

    event HighestBidInc(address bidder, uint bid);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint biddingTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        if (block.timestamp > auctionEndTime) {
            revert("Auction already ended.");
        }

        if (msg.value <= highestBid) {
            revert("There already is a higher bid.");
        }

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidInc(highestBidder, highestBid);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0; // 这个很重要 因为可以反复调用 所以先设定为0 避免被人多次提取
            
            if (!payable(msg.sender).send(amount)) {
                // 如果失败
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        if (block.timestamp <= auctionEndTime) {
            revert("Auction not yet ended.");
        }

        if (ended) {
            revert("auctionEnd has already been called.");
        }

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        payable(beneficiary).transfer(highestBid);
    }
}
