pragma solidity 0.6.8;
/*
    Fast Rent Blockchain Token
    This utility token is used to pay rents and be able the evaluate stays
*/
// TODO buy token, transfer etc..
contract FRBToken {
    string public name;
    string public symbol;
    mapping(address => uint256) public balances;
    
    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }
    
    function mint() public virtual {
        balances[tx.origin]++;  
    }
    
    // TODO: Buy Tokens
    function buyTokens() public {
        
    }
    
    function TransferTokens(address source, address target, uint num_tokens) public {
        require(source == tx.origin);
        require(balances[source] - num_tokens > 0);
        balances[source] -= num_tokens;
        balances[target] += num_tokens;
    }
}

/* 
    This contract is created whenever an owner of property wants to
    put the house available to rent. 
*/ 
contract Rent {
    FRBToken tokenContract; // TODO: is this correct?
    
    uint256 pricePerNight; // in FRB Tokens
    address public token; // Public address of FRB token wallet
    address payable owner_wallet; // Owner Wallet
    uint256 cleanTime;
    
    Client[] clients;
    struct Client {
        address _address;
        uint256 startTime;
        uint256 endTime;
    }
   
    constructor(address payable _wallet, uint256 _pricePerNight, uint _cleanTime, address _token) public {
        owner_wallet = _wallet;
        pricePerNight = _pricePerNight;
        cleanTime = _cleanTime;
        // Public address of FRB Wallet
        // TODO: hardcode it maybe?
        token = _token; 
    }
    
    function deleteContract() public onlyOwner {
        // TODO: refund money to the renters
        // TODO: set contract to deleted
    }
    
    function RentHouse(uint256 startTime, uint256 endTime) public payable returns (bool) {
        uint256 nDays = computeNumDays(startTime, endTime);
        uint256 price = computePrice(nDays); // price in FRB Tokens
        if (isAvailable(startTime, endTime) && haveEnoughFunds()) {
            // TODO: Transfer from renter to owner 
            tokenContract.TransferTokens(msg.sender, owner_wallet, price);
            clients.push(Client(msg.sender, startTime, endTime));
            return true;
        }
        return false;
    }

    function computeNumDays(uint256 startTime, uint256 endTime) internal pure returns (uint) {
        return (endTime - startTime) / 86400; // 60*60*24
    }
    
    function computePrice(uint256 nDays) internal view returns (uint) {
        return nDays * pricePerNight;
    }
    
    function isAvailable(uint256 startTime, uint256 endTime) internal view returns (bool) {
        for (uint i = 0; i < clients.length; i++) {
            bool isFree = endTime+cleanTime < clients[i].startTime || clients[i].endTime+cleanTime < startTime;
            if(!isFree) {
                return false;
            }
        }
        return true;
    }
    
    function haveEnoughFunds() internal returns (bool) {
        // msg.sender
        // TODO: Check balance in token wallets given msg.address
        
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

