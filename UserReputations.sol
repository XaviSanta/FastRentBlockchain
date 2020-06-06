pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;
import './FRBToken.sol';
import './Rent.sol';

/*
    This contract manages the reputation of the users
*/
contract UserReputations {
    FRBToken tokenContract; // Save instance of the FRB token contract
    
    mapping(address => Reputation) reputations;
    struct Reputation {
        uint totalScore;    // The addition of all the ratings
        uint numVotes;      // Number of people who rated the user
    }

    constructor(address _tokenContract) public {
        tokenContract = FRBToken(_tokenContract); // Contract Address of the FRBToken contract, not the wallet
    }
    
    /* 
        The front end should show the return of the function in the most aproppitate way, a reasonable way would be to
        devide the two given values to have the average score of the place
     */
    function getReputation(address _user) public view returns(Reputation memory) {
        return reputations[_user];
    }
    
    /* 
        The ratings can be 1,2,3,4,5, being 1 the worst grade and 5 the best one
        It's similar to how the Play Store rating works

        If the user can vote is checked and then the vote is recorded
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