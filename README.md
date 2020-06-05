# FastRentBlock

## Example to test it: 
1. Create contract **FRBToken**

2. Create contract **UserReputations**
   - Constructor(<`FRBToken contract address`>) from last step

3. RENTER: `0xdD870fA1b7C4700F2BD7f44238821C26f7392148`
	- **Buys** `200 FRB` tokens with `2.000.000 weis`

4. OWNER: `0x583031D1113aD414F02576BD6afaBfb302140225`
	- Creates **Rent** Contract 
  		- _pricePerNight: `20`
    	- _minimumDaysStay: `4`
  		- _hoursBetweenStays: `20`
  		- _contractAddress: <`FRBToken contract address`>
  		- _reputationsContract: <`UserReputations contract address`>

5. RENTER:
	- f.computePrice, f.computeNumDays, f.isAvailable -> Correct
	- f.RentHouse: -*5 nights example*-
		- startTime:	`1592662031`
		- endTime:		`1593094031`
6. Check OWNER balance `+100 FRB` -> Correct
7. Check RENTER balance `-100 FRB` ->  Correct
8. User can now valorate the stay calling f.**evaluateOwner**
	- Parameter is a number from 1 to 5
9. In UserReputation call `getReputation(owner addr)` and it should have changed
