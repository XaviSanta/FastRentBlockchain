pragma solidity 0.6.8;
/*
    Fast Rent Blockchain Token
    This utility token is used to pay rents and be able the evaluate stays
*/
contract FRBToken {
    string public name;
    string public symbol;
    address payable FRBTeam;
    mapping(address => uint256) public balances;

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        FRBTeam = msg.sender;
    }

    function buyTokens() public payable {
        uint256 nWeis = msg.value;
        FRBTeam.transfer(nWeis);
        balances[tx.origin] += nWeis / 1000; // TODO: Price per token to be decided
    }

    function TransferTokens(address source, address target, uint num_tokens) public {
        require(source == tx.origin);
        require(balances[source] - num_tokens > 0);
        balances[source] -= num_tokens;
        balances[target] += num_tokens;
    }

    function getMyBalance() public view returns (uint256) {
        return balances[tx.origin];
    }
}

/* 
    This contract is created whenever an owner of property wants to
    put the house available to rent. 
*/ 
contract Rent {
    FRBToken tokenContract;
    uint256 public pricePerNight;       // in FRB Tokens
    address payable owner_wallet;       // Owner Wallet
    uint256 public hoursBetweenStays;   // Time between clients to clean the property
    uint public minimumDaysStay;        // Minimum Days to rent the property chosen by the owner

    Client[] clients;
    struct Client {
        address _address;
        uint256 startTime;
        uint256 endTime;
    }

    constructor(uint256 _pricePerNight, uint _minimumDaysStay, uint256 _hoursBetweenStays, address _tokenContract) public {
        owner_wallet = msg.sender;
        pricePerNight = _pricePerNight;
        minimumDaysStay = _minimumDaysStay;
        hoursBetweenStays = _hoursBetweenStays;
        tokenContract = FRBToken(_tokenContract); // Contract Address of the FRB Tokne contract, not the wallet
    }

    function deleteContract() public onlyOwner {
        // TODO: refund money to the renters
        // TODO: set contract to deleted
    }

    function RentHouse(uint256 startTime, uint256 endTime) public payable returns (bool) {
        uint256 nDays = computeNumDays(startTime, endTime);
        uint256 price = computePrice(nDays); // price in FRB Tokens
        if (isAvailable(startTime, endTime) && haveEnoughFunds(price)) {
            tokenContract.TransferTokens(msg.sender, owner_wallet, price);
            clients.push(Client(msg.sender, startTime, endTime));
            return true;
        }
        return false;
    }

    function computeNumDays(uint256 startTime, uint256 endTime) public pure returns (uint) {
        return (endTime - startTime) / 1 days;
    }

    function computePrice(uint256 nDays) public view returns (uint) {
        return nDays * pricePerNight;
    }

    function isAvailable(uint256 startTime, uint256 endTime) public view returns (bool) {
        // check if given times overlap with other renters
        for (uint i = 0; i < clients.length; i++) {
            uint256 secondsBetweenStays = hoursBetweenStays * 1 hours;
            bool isFree = endTime+secondsBetweenStays < clients[i].startTime || clients[i].endTime+secondsBetweenStays < startTime;
            if(!isFree) {
                return false;
            }
        }

        // check if dates are future times and it has at least a minimum stay 
        return (startTime > now) && (startTime+(minimumDaysStay*1 days) < endTime);
    }

    function haveEnoughFunds(uint256 _price) internal view  returns (bool) {
        return tokenContract.getMyBalance() > _price;
    }

    function Evaluate() public {
        // TODO: Check user in clients
        // TODO: rate stay
        // TODO: give tokens for rating
    }

    modifier onlyOwner(){
        require(msg.sender == owner_wallet);
        _;
    }
}