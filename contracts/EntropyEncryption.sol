// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropyEncryption
 * @notice Encrypt and store values using EntropyOracle
 * @dev Example demonstrating EntropyOracle integration: using entropy for encryption patterns
 * 
 * This example shows:
 * - How to integrate with EntropyOracle
 * - Using entropy to enhance encryption patterns
 * - Combining user-encrypted values with entropy
 * - Entropy-based encryption key generation
 */
contract EntropyEncryption is ZamaEthereumConfig {
    // Entropy Oracle interface
    IEntropyOracle public entropyOracle;
    
    // Encrypted value stored on-chain
    euint64 private encryptedValue;
    
    bool private initialized;
    
    // Track entropy requests
    mapping(uint256 => bool) public entropyRequests;
    
    event ValueEncrypted(address indexed user);
    event ValueUpdated(address indexed user);
    event EntropyRequested(uint256 indexed requestId, address indexed caller);
    event ValueEncryptedWithEntropy(uint256 indexed requestId, address indexed user);
    
    /**
     * @notice Constructor - sets EntropyOracle address
     * @param _entropyOracle Address of EntropyOracle contract
     */
    constructor(address _entropyOracle) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        entropyOracle = IEntropyOracle(_entropyOracle);
    }
    
    /**
     * @notice Encrypt and store a single value
     * @param encryptedInput Encrypted value from user (externalEuint64)
     * @param inputProof Input proof for encrypted value
     * @dev User encrypts value off-chain, sends to contract
     */
    function encryptAndStore(
        externalEuint64 encryptedInput,
        bytes calldata inputProof
    ) external {
        // Convert external encrypted value to internal
        euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
        
        // Allow contract to use this encrypted value
        FHE.allowThis(internalValue);
        
        // Store encrypted value
        encryptedValue = internalValue;
        initialized = true;
        
        emit ValueEncrypted(msg.sender);
    }
    
    /**
     * @notice Request entropy for encryption enhancement
     * @param tag Unique tag for this request
     * @return requestId Request ID from EntropyOracle
     * @dev Requires 0.00001 ETH fee
     */
    function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        entropyRequests[requestId] = true;
        
        emit EntropyRequested(requestId, msg.sender);
        return requestId;
    }
    
    /**
     * @notice Encrypt and store value with entropy enhancement
     * @param encryptedInput Encrypted value from user
     * @param inputProof Input proof for encrypted value
     * @param requestId Request ID from requestEntropy()
     * @dev Combines user-encrypted value with entropy for enhanced encryption
     */
    function encryptAndStoreWithEntropy(
        externalEuint64 encryptedInput,
        bytes calldata inputProof,
        uint256 requestId
    ) external {
        require(entropyRequests[requestId], "Invalid request ID");
        require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
        
        // Convert external to internal
        euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
        FHE.allowThis(internalValue);
        
        // Get entropy
        euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
        FHE.allowThis(entropy);
        
        // Combine user value with entropy using XOR
        euint64 enhancedValue = FHE.xor(internalValue, entropy);
        FHE.allowThis(enhancedValue);
        
        // Store enhanced encrypted value
        encryptedValue = enhancedValue;
        initialized = true;
        
        entropyRequests[requestId] = false;
        emit ValueEncryptedWithEntropy(requestId, msg.sender);
    }
    
    /**
     * @notice Update stored encrypted value
     * @param encryptedInput New encrypted value
     * @param inputProof Input proof for encrypted value
     */
    function updateValue(
        externalEuint64 encryptedInput,
        bytes calldata inputProof
    ) external {
        require(initialized, "Not initialized");
        
        euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
        FHE.allowThis(internalValue);
        
        encryptedValue = internalValue;
        
        emit ValueUpdated(msg.sender);
    }
    
    /**
     * @notice Get the encrypted value
     * @return Encrypted value (euint64)
     * @dev Returns encrypted value - must be decrypted off-chain to see actual value
     */
    function getEncryptedValue() external view returns (euint64) {
        require(initialized, "Not initialized");
        return encryptedValue;
    }
    
    /**
     * @notice Check if value is initialized
     */
    function isInitialized() external view returns (bool) {
        return initialized;
    }
    
    /**
     * @notice Get EntropyOracle address
     */
    function getEntropyOracle() external view returns (address) {
        return address(entropyOracle);
    }
}
