# EntropyEncryption

Learn how to encrypt a single value using FHE.fromExternal

## 🎓 What You'll Learn

This example teaches you how to use FHEVM to build privacy-preserving smart contracts. You'll learn step-by-step how to implement encrypted operations, manage permissions, and work with encrypted data.

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-encryption-encryptsingle.git
   cd fhevm-example-encryption-encryptsingle
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---

## 📚 Overview

@title EntropyEncryption
@notice Encrypt and store values using encrypted randomness
@dev This example teaches you how to integrate encrypted randomness into your FHEVM contracts: using entropy for encryption patterns
In this example, you will learn:
- How to integrate encrypted randomness
- How to use encrypted randomness to enhance encryption patterns
- Combining user-encrypted values with entropy
- Entropy-based encryption key generation

@notice Constructor - sets encrypted randomness address
@param _encrypted randomness Address of encrypted randomness contract

@notice Encrypt and store a single value
@param encryptedInput Encrypted value from user (externalEuint64)
@param inputProof Input proof for encrypted value
@dev User encrypts value off-chain, sends to contract

@notice Request entropy for encryption enhancement
@param tag Unique tag for this request
@return requestId Request ID from encrypted randomness
@dev Requires 0.00001 ETH fee

@notice Encrypt and store value with entropy enhancement
@param encryptedInput Encrypted value from user
@param inputProof Input proof for encrypted value
@param requestId Request ID from requestEntropy()
@dev Combines user-encrypted value with entropy for enhanced encryption

@notice Update stored encrypted value
@param encryptedInput New encrypted value
@param inputProof Input proof for encrypted value

@notice Get the encrypted value
@return Encrypted value (euint64)
@dev Returns encrypted value - must be decrypted off-chain to see actual value

@notice Check if value is initialized

@notice Get encrypted randomness address



## 🔐 Learn Zama FHEVM Through This Example

This example teaches you how to use the following **Zama FHEVM** features:

### What You'll Learn About

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE.fromExternal()` - Zama FHEVM operation
  - `FHE.allowThis()` - Zama FHEVM operation
  - `FHE.xor()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Handling user-provided encrypted values (Zama FHEVM)
euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
FHE.allowThis(internalValue);

// Mixing with entropy using Zama FHEVM operations
euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
FHE.allowThis(entropy);
euint64 enhancedValue = FHE.xor(internalValue, entropy);
FHE.allowThis(enhancedValue);
```

### FHEVM Concepts You'll Learn

1. **External Encryption**: Learn how to use Zama FHEVM for external encryption
2. **Input Proofs**: Learn how to use Zama FHEVM for input proofs
3. **Permission Management**: Learn how to use Zama FHEVM for permission management
4. **Entropy Integration**: Learn how to use Zama FHEVM for entropy integration

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)



## 🔍 Contract Code

```solidity
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

```

## 🧪 Tests

See [test file](./test/EntropyEncryption.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**encryption**



## 🔗 Related Examples

- [All encryption examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
