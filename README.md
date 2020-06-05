# FastRentBlock

## Example to test it: 
1. create contract FRBToken with
   - `0xff1e56Fa5fC65C38683c3c3801fD0574393CAeB6`

2. **Contract** address is
   - `0xD66bA2586845B4c297a3CB34ec5d566321780513`

3. RENTER: `0xdD870fA1b7C4700F2BD7f44238821C26f7392148`
	- **Buys** `200 FRB` tokens with `2.000.000 weis`

4. OWNER: `0x583031D1113aD414F02576BD6afaBfb302140225`
	- Creates **Rent** Contract 
		- _pricePerNight: `20`
		- _cleanTime: `20`
		- _contractAddress: `0xD66bA2586845B4c297a3CB34ec5d566321780513`

5. RENTER:
	- f.computePrice, f.computeNumDays, f.isAvailable -> Correct
	- f.RentHouse: -*5 nights example*-
		- startTime:	`1592662031`
		- endTime:		`1593094031`
6. Check OWNER balance `+100 FRB` -> Correct
7. Check RENTER balance `-100 FRB` ->  Correct
