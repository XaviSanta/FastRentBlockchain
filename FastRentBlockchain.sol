/** FAST RENT BLOCKCHAIN
 * Group Member Names:
 *      Xavier Santamaria
 *	    Amparo Alías
 *	    Raúl Rivas
 * 	    Judit Boronat
 *	    Arnau Oller
 * 
 * Project Summary:
 *  It contains 3 Contracts: FRBToken, UserReputations and Rent
 *  Rent is created by owners of property, for each property they want to put it to rent.
 *  Renters use FRBToken to pay the rent. And UserReputations contract saves all the 
 *  rates the clients give to the owners in a way that it is inmutable and so users can see
 *  the reputation of others before renting a place.
 *  
 *  Deploy instructions in README. 
 *      Deploy FRBToken Contract,
 *      Deploy ReputationsContract
 *      Deploy Rent Contract from Owner address
 *  Renter: 
 *      Buy tokens, then rent property specifiyng first and last day in epoch time
 *      After the stay call evaluateOwner from Rent contract with a value from 1 to 5
 *  
 *  See README for a better understanding
 *      https://github.com/XaviSanta/FastRentBlockchain
 * 
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;
/*
    Fast Rent Blockchain Utility Token
    This token is used to pay for rent
    Exchange rate is 1 FRB token  === 0.000000000000001 Ether
*/
contract FRBToken {
    string public name;
    string public symbol;
    address payable FRBTeam;
    mapping(address => uint) balances;
    
    constructor() public {
        name = 'Fast Rent Blockchain';
        symbol = 'FRB';
        FRBTeam = msg.sender;
    }

    /* 
        Our exchange rate is the following:
        1 FRB token === 1000 Weis
        which is equivalent to:
        1 FRB token  === 0.000000000000001 Ether
    */
    function buyTokens() public payable {
        uint nWeis = msg.value;
        FRBTeam.transfer(nWeis);
        balances[msg.sender] += nWeis / 1000; //1000 Weis === 1 FRB token
    }

    /* 
        Used to to transactions between users. For example from a renter to an owner
    */
    function transferTokens(address _source, address _target, uint _numTokens) public {
        // this require only allows transfers if you are the owner of the wallet from which the tokens come from
        require(_source == tx.origin);  
        require(balances[_source] > _numTokens);
        balances[_source] -= _numTokens;
        balances[_target] += _numTokens;
    }

    function getBalance(address _wallet) public view returns (uint) {
        return balances[_wallet];
    }
}

/*
    This contract manages the reputation of the users
*/
contract UserReputations {
    mapping(address => Reputation) reputations;
    struct Reputation {
        uint totalScore;    // The addition of all the ratings
        uint numVotes;      // Number of people who rated the user
    }

    constructor() public {}
    
    /* 
        The front end should show the return of the function in the most aproppitate way, a reasonable way would be to
        divide the two given values to have the average score of the place
     */
    function getReputation(address _user) public view returns(Reputation memory) {
        return reputations[_user];
    }
    
    /* 
        The ratings can be 1,2,3,4,5, being 1 the worst grade and 5 the best one
        It's similar to how the Play Store rating works

        If the user can vote is checked and then the vote is recorded
        
        As this function is called from a contrat Rent, the msg.sender will be the contract address
        So that is why we use tx.origin to refer to the user and msg.sender to get the instance
        of the Rent contract.
    */
    function evaluateUser(address _user, uint _valoration) public returns (bool) {
        require(1 <= _valoration && _valoration <= 5, 'Value should be between 1 and 5');
        if(Rent(msg.sender).canThisUserValorateOwner(tx.origin)) { 
            reputations[_user].totalScore += _valoration;
            reputations[_user].numVotes++;
            return true;
        }
        return false;
    }
}

/*
    This contract is created when an owner wants to
    put a house available for rent.

    The owner can decide at the time of creating the contract:
        the price per night
        the minimum days to stay
        the hours between stays that cannot be reserved (because of cleaning)

    The owner can later modify the previous parameters if he wants to

    The contract deals with:
        the availability of the place
        the payments from the renter to the owner
        the ratings to the owner
*/
contract Rent {
    FRBToken tokenContract;             // Save instance of the FRB token contract_address
    UserReputations reputationsContract;// Save instance of the UserReputations contract_address
    uint public pricePerNight;          // in FRB Tokens
    address payable owner_wallet;       // Owner Wallet
    uint public hoursBetweenStays;      // Time between clients to clean the property
    uint public minimumDaysStay;        // Minimum Days to rent the property chosen by the owner

    Client[] clients;       // List of clients that rented the property
    struct Client {         
        address _address;   // Client address
        uint startTime;     // Init day that rent took place
        uint endTime;       // Last day of renting
        bool hasRated;      // Flag to know if user rated or not to make sure users dont rate more than once 
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
    
    /*
        Main function of the contrat. Once client have tokens they can rent the property
        by calling this function with 2 parameters (init day and last day) 
        The function will check all conditions and do the transaction.
        Those conditions are: 
            if time slots are available and correct,
            if user have enough money in the token wallet
        And if everythign worked, it will save the user in the clients array And
        return true. If conditions are not passed, returns false
        
    */
    function RentHouse(uint256 _startTime, uint256 _endTime) public returns (bool) {
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
        The user might not know that the rent should be payed with FBR tokens and/or 
        in case there are not enough funds he is informed about it
     */
    function haveEnoughFunds(uint _price) internal view  returns (bool) {
        require(tokenContract.getBalance(msg.sender) > _price, 'You dont have enough tokens, buy some FBR tokens.');
        return true;
    }

    /*
        The client can call this function once he finished his stay
        to rate the owners place. with an integer from 1 to 5.
        This function calls the reputationsContract.evaluateUser function with parameters
            owner_wallet and _valoration.
        If that function returns true means that the valoration has been submited and saved 
        so now we can set the client attribute has rated to true to make sure he doesnt 
        vote again.
        As one client can rent more than once the property we iterate through the clients 
        array once we found that a client address matches and that he has not rated.
        Otherwise we keep iterating because it could be that he rented the place more than once.
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
        revert('Something bad happened');
    }

    /*
        Checks if the user can vote or not
        We check the following:
            The user should actually be a renter, so he should be in the clients list
            Renter should have completed the stay before voting
            Renter can only vote once for each stay
        
    */
    function canThisUserValorateOwner(address _user) public view returns (bool) {
        for (uint i = 0; i < clients.length; i++) {
            if (clients[i]._address == _user 
                && clients[i].endTime < now // To test the rating system you may want to comment this line
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
            the hoursBetweenStays
            the minimumDayStays
    */

    function setPricePerNight(uint _newPricePerNight) public onlyOwner {
        pricePerNight = _newPricePerNight;
    }

    function setHoursBetweenStays(uint _newHoursBetweenStays) public onlyOwner {
        hoursBetweenStays = _newHoursBetweenStays;
    }
    
    function setMinimumDaysStay(uint _newMinimumDaysStay) public onlyOwner {
        minimumDaysStay = _newMinimumDaysStay;
    }
}