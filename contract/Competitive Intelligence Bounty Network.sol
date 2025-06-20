// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Competitive Intelligence Bounty Network
 * @dev A decentralized platform for competitive intelligence research bounties
 * @author Competitive Intelligence Bounty Network Team
 */
contract Project {
    
    // Struct to represent a bounty
    struct Bounty {
        uint256 id;
        address payable issuer;
        string title;
        string description;
        uint256 reward;
        uint256 deadline;
        address researcher;
        bool isCompleted;
        bool isPaid;
        uint256 createdAt;
        string category; // e.g., "Market Analysis", "Competitor Research", "Pricing Intelligence"
    }
    
    // Struct to represent a submission
    struct Submission {
        uint256 bountyId;
        address researcher;
        string reportHash; // IPFS hash or similar
        uint256 submittedAt;
        bool isApproved;
    }
    
    // State variables
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => Submission) public submissions;
    mapping(address => uint256[]) public researcherBounties;
    mapping(address => uint256[]) public issuerBounties;
    
    uint256 public nextBountyId;
    uint256 public nextSubmissionId;
    uint256 public platformFeePercentage = 5; // 5% platform fee
    address payable public platformOwner;
    
    // Events
    event BountyCreated(
        uint256 indexed bountyId,
        address indexed issuer,
        string title,
        uint256 reward,
        uint256 deadline
    );
    
    event BountyClaimed(
        uint256 indexed bountyId,
        address indexed researcher
    );
    
    event SubmissionMade(
        uint256 indexed submissionId,
        uint256 indexed bountyId,
        address indexed researcher,
        string reportHash
    );
    
    event BountyCompleted(
        uint256 indexed bountyId,
        address indexed researcher,
        uint256 reward
    );
    
    // Modifiers
    modifier onlyIssuer(uint256 _bountyId) {
        require(bounties[_bountyId].issuer == msg.sender, "Only bounty issuer can call this");
        _;
    }
    
    modifier onlyResearcher(uint256 _bountyId) {
        require(bounties[_bountyId].researcher == msg.sender, "Only assigned researcher can call this");
        _;
    }
    
    modifier bountyExists(uint256 _bountyId) {
        require(_bountyId < nextBountyId, "Bounty does not exist");
        _;
    }
    
    modifier notExpired(uint256 _bountyId) {
        require(block.timestamp <= bounties[_bountyId].deadline, "Bounty has expired");
        _;
    }
    
    constructor() {
        platformOwner = payable(msg.sender);
        nextBountyId = 0;
        nextSubmissionId = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new competitive intelligence bounty
     * @param _title Title of the bounty
     * @param _description Detailed description of the research required
     * @param _deadline Deadline for bounty completion (timestamp)
     * @param _category Category of intelligence research
     */
    function createBounty(
        string memory _title,
        string memory _description,
        uint256 _deadline,
        string memory _category
    ) external payable {
        require(msg.value > 0, "Bounty reward must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        bounties[nextBountyId] = Bounty({
            id: nextBountyId,
            issuer: payable(msg.sender),
            title: _title,
            description: _description,
            reward: msg.value,
            deadline: _deadline,
            researcher: address(0),
            isCompleted: false,
            isPaid: false,
            createdAt: block.timestamp,
            category: _category
        });
        
        issuerBounties[msg.sender].push(nextBountyId);
        
        emit BountyCreated(nextBountyId, msg.sender, _title, msg.value, _deadline);
        
        nextBountyId++;
    }
    
    /**
     * @dev Core Function 2: Claim a bounty and submit competitive intelligence report
     * @param _bountyId ID of the bounty to claim and submit for
     * @param _reportHash IPFS hash or similar identifier for the research report
     */
    function claimAndSubmitBounty(
        uint256 _bountyId,
        string memory _reportHash
    ) external bountyExists(_bountyId) notExpired(_bountyId) {
        Bounty storage bounty = bounties[_bountyId];
        
        require(bounty.researcher == address(0), "Bounty already claimed");
        require(!bounty.isCompleted, "Bounty already completed");
        require(bytes(_reportHash).length > 0, "Report hash cannot be empty");
        
        // Claim the bounty
        bounty.researcher = msg.sender;
        researcherBounties[msg.sender].push(_bountyId);
        
        emit BountyClaimed(_bountyId, msg.sender);
        
        // Submit the report
        submissions[nextSubmissionId] = Submission({
            bountyId: _bountyId,
            researcher: msg.sender,
            reportHash: _reportHash,
            submittedAt: block.timestamp,
            isApproved: false
        });
        
        emit SubmissionMade(nextSubmissionId, _bountyId, msg.sender, _reportHash);
        
        nextSubmissionId++;
    }
    
    /**
     * @dev Core Function 3: Approve submission and release payment for competitive intelligence
     * @param _bountyId ID of the bounty
     * @param _submissionId ID of the submission to approve
     */
    function approveAndPayBounty(
        uint256 _bountyId,
        uint256 _submissionId
    ) external onlyIssuer(_bountyId) bountyExists(_bountyId) {
        Bounty storage bounty = bounties[_bountyId];
        Submission storage submission = submissions[_submissionId];
        
        require(!bounty.isCompleted, "Bounty already completed");
        require(!bounty.isPaid, "Bounty already paid");
        require(submission.bountyId == _bountyId, "Submission does not match bounty");
        require(submission.researcher == bounty.researcher, "Submission researcher mismatch");
        require(!submission.isApproved, "Submission already approved");
        
        // Mark as approved and completed
        submission.isApproved = true;
        bounty.isCompleted = true;
        bounty.isPaid = true;
        
        // Calculate payments
        uint256 platformFee = (bounty.reward * platformFeePercentage) / 100;
        uint256 researcherPayment = bounty.reward - platformFee;
        
        // Transfer payments
        payable(bounty.researcher).transfer(researcherPayment);
        platformOwner.transfer(platformFee);
        
        emit BountyCompleted(_bountyId, bounty.researcher, researcherPayment);
    }
    
    // View functions
    function getBounty(uint256 _bountyId) external view returns (Bounty memory) {
        return bounties[_bountyId];
    }
    
    function getSubmission(uint256 _submissionId) external view returns (Submission memory) {
        return submissions[_submissionId];
    }
    
    function getResearcherBounties(address _researcher) external view returns (uint256[] memory) {
        return researcherBounties[_researcher];
    }
    
    function getIssuerBounties(address _issuer) external view returns (uint256[] memory) {
        return issuerBounties[_issuer];
    }
    
    function getActiveBountiesCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextBountyId; i++) {
            if (!bounties[i].isCompleted && bounties[i].deadline > block.timestamp) {
                count++;
            }
        }
        return count;
    }
    
    // Admin functions
    function updatePlatformFee(uint256 _feePercentage) external {
        require(msg.sender == platformOwner, "Only platform owner can update fee");
        require(_feePercentage <= 10, "Fee cannot exceed 10%");
        platformFeePercentage = _feePercentage;
    }
    
    function changePlatformOwner(address payable _newOwner) external {
        require(msg.sender == platformOwner, "Only current owner can change ownership");
        require(_newOwner != address(0), "New owner cannot be zero address");
        platformOwner = _newOwner;
    }
}
