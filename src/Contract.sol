// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract GrantFunder {
    using Counters for Counters.Counter;

    Counters.Counter public _grantNumber;


    bytes32 public constant FUNDER = keccak256(abi.encodePacked("FUNDER"));
    bytes32 public constant RECIPIENT = keccak256(abi.encodePacked("RECIPIENT"));
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));


    mapping(bytes32 => mapping(address => bool)) role;
    mapping(uint256 => Grant) grantById;
    mapping(uint256 => mapping(address => uint256)) contributions;

    struct Grant {
        uint256 goal;
        uint256 startTime;
        uint256 duration;
        uint256 endTime;
        uint256 grantBalance;
        address recipient;
    }



    event roleGranted(bytes32 indexed role, address indexed user);
    event roleRevoked(bytes32 indexed role, address indexed user);

    modifier onlyRole(bytes32 _role) {
        require(role[_role][msg.sender], "You are not allowed here.");
        _;
    }

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    receive() external payable {}


    function _grantRole(bytes32 _role, address _addr) internal {
        role[_role][_addr] = true;
        emit roleGranted(_role, _addr);
    }

    function grantRole(bytes32 _role, address _addr) external onlyRole(ADMIN) {
        _grantRole(_role, _addr);
    }

    function revokeRole(bytes32 _role, address _addr) external onlyRole(ADMIN) {
        require(role[_role][_addr], "User does not have this role.");
        role[_role][_addr] = false;
        emit roleRevoked(_role, _addr);
    }

    function createGrant(uint256 amount, address _reciever) external {
        _grantNumber.increment();
        uint256 grantNumber = _grantNumber.current();
        Grant storage grant = grantById[grantNumber];
        grant.goal = amount * 1 ether;
        grant.startTime = block.timestamp;
        grant.duration = 1 weeks;
        grant.endTime = grant.startTime + grant.duration;
        grant.recipient = _reciever;
    }

    function deposit(uint256 amount, uint256 grantNo) payable external onlyRole(FUNDER) {
        //require(grantById[grantNo], "This grant does not exist.");
        Grant memory grant = grantById[grantNo];
        require(grant.endTime >= block.timestamp, "This campaign is over.");
        require(msg.sender.balance >= amount, "You do not have enough funds.");

        Grant storage grantBal = grantById[grantNo];
        grantBal.grantBalance += amount;
        contributions[grantNo][msg.sender] += amount;
        payable(address(this)).transfer(amount);
    }

    function reclaimDeposit(uint256 grantNo) payable external onlyRole(FUNDER) {
        Grant storage grant = grantById[grantNo];
        // Remember to add in || in case block.timestamp > endTime but goal hasn't been reached. 
        require((grant.endTime >= block.timestamp && grant.goal > grant.grantBalance) || grant.goal > grant.grantBalance, "This campaign has ended and has met its fundraising goal.");
        require(contributions[grantNo][msg.sender] > 0, "You have not contributed to this campaign.");
        uint256 _amount = contributions[grantNo][msg.sender];
        contributions[grantNo][msg.sender] = 0;
        grant.grantBalance -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function claimGrant(uint256 grantNum) payable external onlyRole(RECIPIENT) {
        Grant storage grant = grantById[grantNum];
        require(grant.recipient == msg.sender, "You are not the recipient.");
        require(block.timestamp > grant.endTime || grant.grantBalance >= grant.goal, "Campaign not over or fundraising goal not reached.");
        //require(grant.grantBalance > grant.goal);
        uint256 _amount = grant.grantBalance;
        grant.grantBalance = 0;
        payable(msg.sender).transfer(_amount);
    }
}