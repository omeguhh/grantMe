# GrantMe
A grant contract made with Foundry. Wrote this to further test Forge capabilities and get comfortable with using it for testing. 

## Grant Contract
Allows an `Admin` to grant a `role` to any address. Anyone can create a Grant, funding goal, and recipient. 

Only recipients of the particular grant can claim the grant. Users who are `funders` can reclaim their deposits if the timelock has not unlocked OR if the fundraising goal is not reached.

Tests cover cases surrounding valid users, timelocks, depositing and withdrawing the correct amounts, who is able to grant roles, who is able to deposit, withdraw, and when they are able to do so.
