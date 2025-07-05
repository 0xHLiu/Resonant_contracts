// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";

/**
 * @title TokenDistributor
 * @dev A contract for confidential token distribution on Oasis Protocol using Sapphire
 * Distributes 90% of tokens to voice talent and 10% to protocol
 */
contract TokenDistributor {
    // Distribution percentages (in basis points: 10000 = 100%)
    uint256 public constant VOICE_TALENT_PERCENTAGE = 9000; // 90%
    uint256 public constant PROTOCOL_PERCENTAGE = 1000;     // 10%
    
    // Addresses for distribution
    address public immutable voiceTalentAddress;
    address public immutable protocolAddress;
    
    // Events
    event TokensDistributed(
        address indexed sender,
        address indexed voiceTalent,
        address indexed protocol,
        uint256 totalAmount,
        uint256 voiceTalentAmount,
        uint256 protocolAmount,
        bytes32 confidentialId
    );
    
    event DistributionConfigUpdated(
        address indexed voiceTalent,
        address indexed protocol,
        uint256 voiceTalentPercentage,
        uint256 protocolPercentage
    );
    
    // Struct for confidential distribution data
    struct DistributionData {
        address sender;
        uint256 amount;
        uint256 timestamp;
        bytes32 confidentialId;
    }
    
    // Mapping to store confidential distribution records
    mapping(bytes32 => DistributionData) private _distributions;
    
    // Array to track all distribution IDs
    bytes32[] private _distributionIds;
    
    /**
     * @dev Constructor sets the distribution addresses
     * @param _voiceTalentAddress Address to receive 90% of tokens
     * @param _protocolAddress Address to receive 10% of tokens
     */
    constructor(
        address _voiceTalentAddress,
        address _protocolAddress
    ) {
        require(_voiceTalentAddress != address(0), "Invalid voice talent address");
        require(_protocolAddress != address(0), "Invalid protocol address");
        require(_voiceTalentAddress != _protocolAddress, "Addresses must be different");
        
        voiceTalentAddress = _voiceTalentAddress;
        protocolAddress = _protocolAddress;
        
        emit DistributionConfigUpdated(
            _voiceTalentAddress,
            _protocolAddress,
            VOICE_TALENT_PERCENTAGE,
            PROTOCOL_PERCENTAGE
        );
    }
    
    /**
     * @dev Distribute tokens with confidential computing
     * @param tokenAddress The ERC20 token contract address
     * @param amount The total amount to distribute
     * @param confidentialId Optional confidential identifier for tracking
     */
    function distributeTokens(
        address tokenAddress,
        uint256 amount,
        bytes32 confidentialId
    ) external {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        // Generate confidential ID if not provided
        if (confidentialId == bytes32(0)) {
            confidentialId = _generateConfidentialId(msg.sender, amount);
        }
        
        // Calculate distribution amounts
        uint256 voiceTalentAmount = (amount * VOICE_TALENT_PERCENTAGE) / 10000;
        uint256 protocolAmount = amount - voiceTalentAmount; // Ensures exact distribution
        
        // Transfer tokens to voice talent (90%)
        _transferTokens(tokenAddress, voiceTalentAddress, voiceTalentAmount);
        
        // Transfer tokens to protocol (10%)
        _transferTokens(tokenAddress, protocolAddress, protocolAmount);
        
        // Store confidential distribution data
        _distributions[confidentialId] = DistributionData({
            sender: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            confidentialId: confidentialId
        });
        
        _distributionIds.push(confidentialId);
        
        emit TokensDistributed(
            msg.sender,
            voiceTalentAddress,
            protocolAddress,
            amount,
            voiceTalentAmount,
            protocolAmount,
            confidentialId
        );
    }
    
    /**
     * @dev Distribute native tokens (ETH/ROSE) with confidential computing
     * @param confidentialId Optional confidential identifier for tracking
     */
    function distributeNativeTokens(bytes32 confidentialId) external payable {
        require(msg.value > 0, "Must send native tokens");
        
        // Generate confidential ID if not provided
        if (confidentialId == bytes32(0)) {
            confidentialId = _generateConfidentialId(msg.sender, msg.value);
        }
        
        // Calculate distribution amounts
        uint256 voiceTalentAmount = (msg.value * VOICE_TALENT_PERCENTAGE) / 10000;
        uint256 protocolAmount = msg.value - voiceTalentAmount;
        
        // Transfer native tokens to voice talent (90%)
        (bool success1, ) = voiceTalentAddress.call{value: voiceTalentAmount}("");
        require(success1, "Transfer to voice talent failed");
        
        // Transfer native tokens to protocol (10%)
        (bool success2, ) = protocolAddress.call{value: protocolAmount}("");
        require(success2, "Transfer to protocol failed");
        
        // Store confidential distribution data
        _distributions[confidentialId] = DistributionData({
            sender: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            confidentialId: confidentialId
        });
        
        _distributionIds.push(confidentialId);
        
        emit TokensDistributed(
            msg.sender,
            voiceTalentAddress,
            protocolAddress,
            msg.value,
            voiceTalentAmount,
            protocolAmount,
            confidentialId
        );
    }
    
    /**
     * @dev Get distribution data by confidential ID (only accessible by sender)
     * @param confidentialId The confidential identifier
     * @return sender The address that initiated the distribution
     * @return amount The total amount distributed
     * @return timestamp When the distribution occurred
     */
    function getDistributionData(bytes32 confidentialId) 
        external 
        view 
        returns (address sender, uint256 amount, uint256 timestamp) 
    {
        DistributionData memory data = _distributions[confidentialId];
        require(data.sender != address(0), "Distribution not found");
        require(data.sender == msg.sender, "Access denied");
        
        return (data.sender, data.amount, data.timestamp);
    }
    
    /**
     * @dev Get encrypted distribution data using Sapphire encryption
     * @param confidentialId The confidential identifier
     * @param key The encryption key
     * @param nonce The nonce for encryption
     * @return encryptedData The encrypted distribution data
     */
    function getEncryptedDistributionData(bytes32 confidentialId, bytes32 key, bytes32 nonce) 
        external 
        view 
        returns (bytes memory encryptedData) 
    {
        DistributionData memory data = _distributions[confidentialId];
        require(data.sender != address(0), "Distribution not found");
        require(data.sender == msg.sender, "Access denied");
        
        // Create data to encrypt
        bytes memory dataToEncrypt = abi.encode(
            data.sender,
            data.amount,
            data.timestamp,
            data.confidentialId
        );
        
        // Encrypt using Sapphire's encryption
        encryptedData = Sapphire.encrypt(key, nonce, dataToEncrypt, "");
    }
    
    /**
     * @dev Get all distribution IDs for the caller
     * @return Array of confidential IDs
     */
    function getMyDistributionIds() external view returns (bytes32[] memory) {
        bytes32[] memory myIds = new bytes32[](_distributionIds.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < _distributionIds.length; i++) {
            if (_distributions[_distributionIds[i]].sender == msg.sender) {
                myIds[count] = _distributionIds[i];
                count++;
            }
        }
        
        // Resize array to actual count
        bytes32[] memory result = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = myIds[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get total distributions count
     * @return Total number of distributions
     */
    function getTotalDistributions() external view returns (uint256) {
        return _distributionIds.length;
    }
    
    /**
     * @dev Internal function to transfer ERC20 tokens
     */
    function _transferTokens(address tokenAddress, address to, uint256 amount) internal {
        require(IERC20(tokenAddress).transferFrom(msg.sender, to, amount), "Token transfer failed");
    }
    
    /**
     * @dev Generate a confidential ID based on sender and amount using Sapphire
     */
    function _generateConfidentialId(address sender, uint256 amount) internal view returns (bytes32) {
        // Use Sapphire's random number generation for better confidentiality
        bytes memory randomBytes = Sapphire.randomBytes(32, "");
        bytes32 randomSeed = bytes32(randomBytes);
        return keccak256(abi.encodePacked(
            sender,
            amount,
            block.timestamp,
            randomSeed
        ));
    }
    
    /**
     * @dev Emergency function to recover stuck tokens (only owner)
     */
    function emergencyRecoverTokens(address tokenAddress, address to) external {
        require(msg.sender == voiceTalentAddress || msg.sender == protocolAddress, "Not authorized");
        
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance > 0) {
            _transferTokens(tokenAddress, to, balance);
        }
    }
    
    /**
     * @dev Emergency function to recover stuck native tokens (only authorized addresses)
     */
    function emergencyRecoverNative(address to) external {
        require(msg.sender == voiceTalentAddress || msg.sender == protocolAddress, "Not authorized");
        
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = to.call{value: balance}("");
            require(success, "Native token recovery failed");
        }
    }
    
    // Allow contract to receive native tokens
    receive() external payable {}
}

// Interface for ERC20 tokens
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
} 