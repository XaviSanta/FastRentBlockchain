pragma solidity 0.6.8;
import './FRBToken.sol';
import './UserReputations.sol';
/*
    This contract is created when an owner wants to
    put a house available for rent.

    The owner can decide at the time of creating the contract:
        the price per night
        the minimum days to stay
        the hours between stays that cannot be reserved 

    The owner can later modify the previous parameters if he wants to

    The contract deals with:
        the availability of the place
        the payments from the renter to the owner
        the ratings to the owner
    
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
        bool hasRated;
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
        reputationsContract = UserReputations(_reputationsContract); // Contract Address of the FRB Token contract, not the wallet
    }
    
    function RentHouse(uint256 _startTime, uint256 _endTime) public payable returns (bool) {
        uint nDays = computeNumDays(_startTime, _endTime);
        uint nTokens = computePrice(nDays); // price in FRB Tokens
        if (isAvailable(_startTime, _endTime) && haveEnoughFunds(nTokens)) {
            tokenContract.transferTokens(msg.sender, owner_wallet, nTokens);
            clients.push(Client(msg.sender, _startTime, _endTime, false));
            return true;
        }
        return false;
    }

    /*
        The owner can put  minimum days as a requirement we also needed sinc the price is computed in function of days
     */
    function computeNumDays(uint _startTime, uint _endTime) public pure returns (uint) {
        return (_endTime - _startTime) / 1 days;
    }

    /*
        The price is computed as FRB Tokens
     */
    function computePrice(uint _nDays) public view returns (uint) {
        return _nDays * pricePerNight;
    }

    /*
        We check:
            Overlappings with clients
            Overlaping with hours between stays
            User is renting a stay in the future and not the past
            End time is later than start time
            If the minimum stay is satisfied
    */
    function isAvailable(uint _startTime, uint _endTime) public view returns (bool) {
        // check if the given days do not overlap neither with another client or the hours between stays
        for (uint i = 0; i < clients.length; i++) {
            uint secondsBetweenStays = hoursBetweenStays * 1 hours;
            bool isFree = _endTime+secondsBetweenStays < clients[i].startTime
                || clients[i].endTime+secondsBetweenStays < _startTime;
            require(isFree, 'Given days are not free');
        }

        require(_startTime > now, 'Start time should be a future time');
        require(_startTime < _endTime, 'Start time should be before end time');
        require(_endTime - _startTime >= minimumDaysStay*1 days, 'Minimum days stay requirement failed');
        return true;
    }

    /*
        The user might not know that the rent should be payed with FBR tokens and/or in case there are not enough funds he is informed about it
     */
    function haveEnoughFunds(uint _price) internal view  returns (bool) {
        require(tokenContract.getBalance(msg.sender) > _price, 'You dont have enough tokens, buy some FBR tokens.');
        return true;
    }

    /*
        Check if the user can vote or not
     */
    function evaluateOwner(uint _valoration) public returns (bool) {
        if(reputationsContract.evaluateUser(owner_wallet, _valoration)) {
            for (uint i = 0; i < clients.length; i++) {
                if (clients[i]._address == tx.origin && !clients[i].hasRated) {
                    clients[i].hasRated = true;
                    return true;
                }
            }
        }
        return false;
    }

    /*
        We check the following:
            The user should actually be a renter, so he should be in the clients list
            Renter should have completed the stay before voting
            Renter can only vote once for each stay
    */
    function canThisUserValorateOwner(address _user) public view returns (bool) {
        for (uint i = 0; i < clients.length; i++) {
            if (clients[i]._address == _user 
                && clients[i].endTime < now
                && !clients[i].hasRated) {
                return true;
            }
        }
        return false;
    }

    /* 
        This modifier allows us to define functions that can only be executed by the owner of the contract, which will be the owner of the place
    */
    modifier onlyOwner(){
        require(msg.sender == owner_wallet);
        _;
    }

    /*
        We allow the (only)owner to modify some parameters:
            the pricePerNight
            the HoursBetweenStays
            the minimumDayStays
    */

    function setPricePerNight(uint _newPricePerNight) public onlyOwner {
        pricePerNight = _newPricePerNight;
    }

    function setHoursBetweenStays(uint _newHoursBetweenStays) public onlyOwner{
        hoursBetweenStays = _newHoursBetweenStays;
    }
    
    function setMinimumDaysStay(uint _newMinimumDaysStay) public onlyOwner{
        minimumDaysStay = _newMinimumDaysStay;
    }
}