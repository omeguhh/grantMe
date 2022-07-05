// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/GrantFunder.sol";

contract ContractTest is Test {
    using stdStorage for StdStorage;

    receive() external payable {}
    
    GrantFunder grantFunder;
    address funder = payable(address(10));
    address recipient = payable(address(11));
    address scammer = payable(address(12));

    function setUp() public {
        grantFunder = new GrantFunder();
        // grantFunder.grantRole(0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42, funder);
        vm.deal(funder, 10 ether);
    }

    function testAdminCanGrantRoles() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        grantFunder.grantRole(0xc0cf426ad0509561ffb2d46a80ad669faafcff4e3bac22e9033747ae052bcf3e, recipient);
        grantFunder.grantRole(0xc0cf426ad0509561ffb2d46a80ad669faafcff4e3bac22e9033747ae052bcf3e, scammer);
        bool slot = stdstore
            .target(address(grantFunder))
            .sig(grantFunder.role.selector)
            .with_key(bytes32(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945))
            .with_key(funder)
            .read_bool();
        
        assertEq(slot, true);
    }
    
    function testNotAdminCannotGrantRoles() public {
        vm.prank(address(2));
        vm.expectRevert(abi.encodePacked("You are not allowed here."));
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
    }

    function testAdminRevokeRole() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        grantFunder.revokeRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        bool slot = stdstore
            .target(address(grantFunder))
            .sig(grantFunder.role.selector)
            .with_key(bytes32(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945))
            .with_key(address(1))
            .read_bool();
        
        assertEq(slot, false);
    }

    function testNotAdminCannotRevokeRole() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.prank(address(2));
        vm.expectRevert(abi.encodePacked("You are not allowed here."));
        grantFunder.revokeRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
    }

    function testCreateGrant() public {
        grantFunder.createGrant(1, recipient);
        uint256 slot = stdstore
            .target(address(grantFunder))
            .sig(grantFunder.grantById.selector)
            .with_key(1)
            .depth(0)
            .read_uint();
        emit log_uint(slot);
        assertEq(slot, 1 ether);
    }

    function testDeposit() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.deal(funder, 2 ether);
        emit log_uint(funder.balance);
        emit log_uint(address(grantFunder).balance);
        grantFunder.createGrant(1, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
        emit log_uint(funder.balance);
        emit log_uint(address(grantFunder).balance);
    }

    function testOnlyFunderCanDeposit() public {
        grantFunder.createGrant(1, recipient);
        vm.deal(recipient, 2 ether);
        vm.prank(recipient);
        vm.expectRevert(abi.encodePacked("You are not allowed here."));
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
    }

    function testCannotBeRefundedAfterGoalMet() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.deal(funder, 2 ether);
        emit log_uint(funder.balance);
        grantFunder.createGrant(1, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
        vm.prank(funder);
        vm.expectRevert(abi.encodePacked("This campaign has ended and has met its fundraising goal."));
        grantFunder.reclaimDeposit(1);
        emit log_uint(funder.balance);
    }

    function testCannontBeRefundedIfNoContribution() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, scammer);
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.deal(funder, 3 ether);
        emit log_uint(funder.balance);
        grantFunder.createGrant(2, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
        vm.prank(scammer);
        vm.expectRevert(abi.encodePacked("You have not contributed to this campaign."));
        grantFunder.reclaimDeposit(1);
        emit log_uint(funder.balance);
        emit log_uint(scammer.balance);
    }

    function testCanBeRefundedBeforeEndTime() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.deal(funder, 3 ether);
        vm.deal(address(grantFunder), 10 ether);
        emit log_uint(funder.balance);
        grantFunder.createGrant(2, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
        vm.prank(funder);
        //emit log_uint(address(grantFunder).balance);
        grantFunder.reclaimDeposit(1);
        emit log_uint(funder.balance);
        console.log(address(grantFunder));
    }

    function testCanBeRefundedAfterEndTime() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.deal(funder, 3 ether);
        vm.deal(address(grantFunder), 10 ether);
        emit log_uint(funder.balance);
        grantFunder.createGrant(2, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
        skip(1000000000000);
        vm.prank(funder);
        //emit log_uint(address(grantFunder).balance);
        grantFunder.reclaimDeposit(1);
        emit log_uint(funder.balance);
        console.log(address(grantFunder));
    }

    function testContributions() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        vm.deal(funder, 2 ether);
        emit log_uint(funder.balance);
        grantFunder.createGrant(2, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 1 ether}(1 ether, 1);
        uint256 slot = stdstore
            .target(address(grantFunder))
            .sig(grantFunder.contributions.selector)
            .with_key(1)
            .with_key(funder)
            .read_uint();
        emit log_uint(slot);
        assertEq(slot + 1 ether, 2 ether);

    }

    function testCanClaimFundsBeforeTimeExpires() public {
        grantFunder.grantRole(0x4f506ac322e467a10b006ee5ecfc5b7781c5c43d2ffbc468de868900d27b9945, funder);
        grantFunder.grantRole(0xc0cf426ad0509561ffb2d46a80ad669faafcff4e3bac22e9033747ae052bcf3e, recipient);
        vm.deal(funder, 10 ether);
        emit log_uint(funder.balance);
        grantFunder.createGrant(2, recipient);
        vm.prank(funder);
        grantFunder.deposit{value: 2 ether}(2 ether, 1);
        vm.prank(recipient);
        grantFunder.claimGrant(1);
        emit log_uint(recipient.balance);
    }

}
