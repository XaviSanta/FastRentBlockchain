pragma solidity 0.6.8;
import './FRBToken.sol';
import './Rent.sol';

contract UserReputations {
    FRBToken tokenContract; // Save instance of the FRB token contract
    
    mapping(address => Reputation) reputations;
    struct Reputation {
        uint averageScore;  // Score from 1 to 5
        uint numVotes;      // Number of people who rated the user
    }
    
    constructor(address _tokenContract) public {
        tokenContract = FRBToken(_tokenContract); // Contract Address of the FRB Tokne contract, not the wallet
    }
    
    function getReputation(address _user) public view returns(uint) {
        return reputations[_user].averageScore;
    }
    
    // from 1 to 5
    function evaluateUser(address _user, uint _valoration) public returns (bool) {
        if (1 <= _valoration && _valoration <= 5) {
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
