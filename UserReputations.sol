pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;
import './Rent.sol';

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