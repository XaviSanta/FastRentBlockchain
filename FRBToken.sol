pragma solidity 0.6.8;
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
        require(_source == tx.origin);
        require(balances[_source] > _numTokens);
        balances[_source] -= _numTokens;
        balances[_target] += _numTokens;
    }

    function getBalance(address _wallet) public view returns (uint) {
        return balances[_wallet];
    }
}