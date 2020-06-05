pragma solidity 0.6.8;
/*
    Fast Rent Blockchain Token
    This utility token is used to pay rents and be able the evaluate stays
*/
contract FRBToken {
    string public name;
    string public symbol;
    address payable FRBTeam;
    mapping(address => uint) public balances;
    
    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        FRBTeam = msg.sender;
    }

    function buyTokens() public payable {
        uint nWeis = msg.value;
        FRBTeam.transfer(nWeis);
        balances[tx.origin] += nWeis / 1000; // TODO: Price per token to be decided
    }

    function TransferTokens(address _source, address _target, uint _numTokens) public {
        require(_source == tx.origin);
        require(balances[_source] > _numTokens);
        balances[_source] -= _numTokens;
        balances[_target] += _numTokens;
    }

    function getMyBalance() public view returns (uint) {
        return balances[tx.origin];
    }
}

contract UserReputations {
    FRBToken tokenContract; // Save instance of the FRB token contract
    
    mapping(address => Reputation) reputations;
    struct Reputation {
        uint averageScore;
        uint numVotes;
    }
    
    constructor(address _tokenContract) public {
        tokenContract = FRBToken(_tokenContract); // Contract Address of the FRB Tokne contract, not the wallet
    }
    
    function getReputation(address _user) public view returns(uint) {
        return reputations[_user].averageScore;
    }
    
    // from 1 to 5
    function evaluateUser(address _user, uint _valoration) public returns (bool) {
        if (1 <= _valoration && _valoration >= 5) {
            // Checks if the addres is from a Rent Contract and renter have rented the house
            // msg.sender is the address of the rent contract and tx origin is the renter who called 
            // the evaluate function in Rent Contract
            if(Rent(msg.sender).canThisUserValorateOwner(tx.origin)) {
                uint numVotes = reputations[_user].numVotes;
                uint averageScore = reputations[_user].averageScore;
                uint newScore = averageScore * (numVotes/(numVotes+1)) + (_valoration/(numVotes+1));
                reputations[_user] = Reputation(newScore, numVotes+1); // Update reputation of user
                return true;
            }
        }
        return false;
    }
}
/* 
    This contract is created whenever an owner of property wants to
    put the house available to rent. 
*/ 
contract Rent {
    FRBToken tokenContract;             // Save instance of the FRB token contract_address
    UserReputations reputationsContract;// Save instance of the FRB token contract_address
    uint public pricePerNight;          // in FRB Tokens
    address payable owner_wallet;       // Owner Wallet
    uint public hoursBetweenStays;      // Time between clients to clean the property
    uint public minimumDaysStay;        // Minimum Days to rent the property chosen by the owner

    Client[] clients;
    struct Client {
        address _address;
        uint startTime;
        uint endTime;
    }

    constructor(
        uint _pricePerNight,
        uint _minimumDaysStay,
        uint _hoursBetweenStays,
        address _tokenContract,
        address _reputationsContract
        ) public {
        owner_wallet = msg.sender;
        pricePerNight = _pricePerNight;
        minimumDaysStay = _minimumDaysStay;
        hoursBetweenStays = _hoursBetweenStays;
        tokenContract = FRBToken(_tokenContract); // Contract Address of the FRB Tokne contract, not the wallet
        reputationsContract = UserReputations(_reputationsContract); // Contract Address of the FRB Tokne contract, not the wallet
    }

    function RentHouse(uint256 _startTime, uint256 _endTime) public payable returns (bool) {
        uint nDays = computeNumDays(_startTime, _endTime);
        uint price = computePrice(nDays); // price in FRB Tokens
        if (isAvailable(_startTime, _endTime) && haveEnoughFunds(price)) {
            tokenContract.TransferTokens(msg.sender, owner_wallet, price);
            clients.push(Client(msg.sender, _startTime, _endTime));
            return true;
        }
        return false;
    }

    function computeNumDays(uint _startTime, uint _endTime) public pure returns (uint) {
        return (_endTime - _startTime) / 1 days;
    }

    function computePrice(uint _nDays) public view returns (uint) {
        return _nDays * pricePerNight;
    }

    function isAvailable(uint _startTime, uint _endTime) public view returns (bool) {
        // check if given times overlap with other renters
        for (uint i = 0; i < clients.length; i++) {
            uint secondsBetweenStays = hoursBetweenStays * 1 hours;
            bool isFree = _endTime+secondsBetweenStays < clients[i].startTime
                || clients[i].endTime+secondsBetweenStays < _startTime;
            if(!isFree) {
                return false;
            }
        }

        // check if dates are future times and it has at least a minimum stay 
        return (_startTime > now) && (_startTime+(minimumDaysStay*1 days) < _endTime);
    }

    function haveEnoughFunds(uint _price) internal view  returns (bool) {
        return tokenContract.getMyBalance() > _price;
    }

    function evaluateOwner(uint _valoration) public returns (bool) {
        return reputationsContract.evaluateUser(owner_wallet, _valoration);
    }

    function canThisUserValorateOwner(address _user) public view returns (bool) {
        for (uint i = 0; i < clients.length; i++) {
            if (clients[i]._address == _user && clients[i].endTime < now) {
                return true;
            }
        }
        return false;
    }

    modifier onlyOwner(){
        require(msg.sender == owner_wallet);
        _;
    }
}