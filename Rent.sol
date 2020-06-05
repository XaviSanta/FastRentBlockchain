pragma solidity 0.6.8;
import './FRBToken.sol';
import './UserReputations.sol';
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
        uint nTokens = computePrice(nDays); // price in FRB Tokens
        if (isAvailable(_startTime, _endTime) && haveEnoughFunds(nTokens)) {
            tokenContract.transferTokens(msg.sender, owner_wallet, nTokens);
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
        return tokenContract.getBalance(msg.sender) > _price;
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