pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;
import './FRBToken.sol';
import './Rent.sol';

contract UserReputations {
    FRBToken tokenContract; // Save instance of the FRB token contract
    
    mapping(address => Reputation) reputations;
    struct Reputation {
        uint totalScore; 
        uint numVotes;      // Number of people who rated the user
    }
    
    constructor(address _tokenContract) public {
        tokenContract = FRBToken(_tokenContract); // Contract Address of the FRB Tokne contract, not the wallet
    }
    
    function getReputation(address _user) public view returns(Reputation memory) {
        return reputations[_user];
    }
    
    // from 1 to 5
    function evaluateUser(address _user, uint _valoration) public returns (bool) {
        require(1 <= _valoration && _valoration <= 5, 'Value should be between 1 and 5');
        // Checks if the addres is from a Rent Contract and renter have rented the house
        // msg.sender is the address of the rent contract and tx origin is the renter who called 
        // the evaluate function in Rent Contract
        if(Rent(msg.sender).canThisUserValorateOwner(tx.origin)) {
            reputations[_user].totalScore += _valoration;
            reputations[_user].numVotes++;
            return true;
        }
        return false;
    }
}