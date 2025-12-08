# EntropyEncryption

Encrypt and store values using EntropyOracle

## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor arg is fixed to EntropyOracle `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📋 Overview

This example demonstrates **encryption** concepts in FHEVM with **EntropyOracle integration**:
- Integrating with EntropyOracle
- Using entropy to enhance encryption patterns
- Combining user-encrypted values with entropy
- Entropy-based encryption key generation

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **How to encrypt values off-chain** using FHEVM SDK
2. **How to send encrypted values to contracts** with input proofs
3. **How to store encrypted values** on-chain
4. **How to enhance encryption with entropy** from EntropyOracle
5. **How to update encrypted values** after initial storage
6. **The importance of `FHE.allowThis()`** for stored values

## 💡 Why This Matters

Encryption is fundamental to FHEVM. With EntropyOracle, you can:
- **Add randomness** to encrypted values without revealing them
- **Enhance security** by mixing entropy with user-encrypted data
- **Create unpredictable patterns** in encrypted storage
- **Learn the foundation** for more complex encryption patterns

## 🔍 How It Works

### Contract Structure

The contract has three main components:

1. **Basic Encryption**: Encrypt and store values without entropy
2. **Entropy Request**: Request randomness from EntropyOracle
3. **Entropy-Enhanced Encryption**: Combine user value with entropy

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
constructor(address _entropyOracle) {
    require(_entropyOracle != address(0), "Invalid oracle address");
    entropyOracle = IEntropyOracle(_entropyOracle);
}
```

**What it does:**
- Takes EntropyOracle address as parameter
- Validates the address is not zero
- Stores the oracle interface

**Why it matters:**
- Must use the correct oracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

#### 2. Encrypt and Store

```solidity
function encryptAndStore(
    externalEuint64 encryptedInput,
    bytes calldata inputProof
) external {
    euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
    FHE.allowThis(internalValue);
    encryptedValue = internalValue;
    initialized = true;
}
```

**What it does:**
- Accepts encrypted value from external source (frontend)
- Validates encrypted value using input proof
- Converts external encrypted value to internal format
- Grants permission to use the value
- Stores it as encrypted value

**Key concepts:**
- **Off-chain encryption**: User encrypts value using FHEVM SDK before sending
- **Input proof**: Cryptographic proof validating the encrypted value
- **External to internal**: `FHE.fromExternal()` converts format

**Why it's needed:**
- Contract needs to store encrypted values
- Can be called multiple times (updates value)

#### 3. Request Entropy

```solidity
function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
    require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
    
    requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
    entropyRequests[requestId] = true;
    
    return requestId;
}
```

**What it does:**
- Validates fee payment (0.00001 ETH)
- Requests entropy from EntropyOracle
- Stores request ID for later use
- Returns request ID

#### 4. Encrypt with Entropy

```solidity
function encryptAndStoreWithEntropy(
    externalEuint64 encryptedInput,
    bytes calldata inputProof,
    uint256 requestId
) external {
    require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
    
    euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
    FHE.allowThis(internalValue);
    
    euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
    FHE.allowThis(entropy);  // CRITICAL!
    
    euint64 enhancedValue = FHE.xor(internalValue, entropy);
    FHE.allowThis(enhancedValue);
    
    encryptedValue = enhancedValue;
}
```

**What it does:**
- Validates request ID and fulfillment status
- Converts external encrypted input to internal
- Gets encrypted entropy from oracle
- **Grants permission** to use entropy (CRITICAL!)
- Combines user value with entropy using XOR
- Stores entropy-enhanced value

**Key concepts:**
- **XOR mixing**: Combines user value with entropy
- **Enhanced encryption**: Result has added randomness
- **Multiple `FHE.allowThis()` calls**: Required for each encrypted value

**Why XOR:**
- XOR adds randomness to encrypted value
- Result: Entropy-enhanced encryption (not just user value)

**Common mistake:**
- Forgetting `FHE.allowThis(entropy)` causes `SenderNotAllowed()` error

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, and EntropyEncryption
   - Returns all contract instances

2. **Test: Basic Encryption**
   ```typescript
   it("Should encrypt and store value", async function () {
     const input = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input.add64(42);
     const encryptedInput = await input.encrypt();
     
     await contract.encryptAndStore(encryptedInput.handles[0], encryptedInput.inputProof);
     
     expect(await contract.isInitialized()).to.be.true;
   });
   ```
   - Creates encrypted input (value: 42)
   - Encrypts using FHEVM SDK
   - Calls `encryptAndStore()` with handle and proof
   - Verifies storage succeeded

3. **Test: Update Value**
   ```typescript
   it("Should update encrypted value", async function () {
     // ... initial encryption ...
     
     const input2 = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input2.add64(100);
     const encryptedInput2 = await input2.encrypt();
     
     await contract.updateValue(encryptedInput2.handles[0], encryptedInput2.inputProof);
   });
   ```
   - Updates stored encrypted value
   - New value replaces old value

4. **Test: Entropy Request**
   ```typescript
   it("Should request entropy", async function () {
     const tag = hre.ethers.id("test-encrypt");
     const fee = await oracle.getFee();
     await expect(
       contract.requestEntropy(tag, { value: fee })
     ).to.emit(contract, "EntropyRequested");
   });
   ```
   - Requests entropy with unique tag
   - Pays required fee
   - Verifies request event is emitted

### Expected Test Output

```
  EntropyEncryption
    Deployment
      ✓ Should deploy successfully
      ✓ Should not be initialized by default
      ✓ Should have EntropyOracle address set
    Basic Encryption
      ✓ Should encrypt and store value
      ✓ Should update encrypted value
    Entropy-Enhanced Encryption
      ✓ Should request entropy
      ✓ Should encrypt and store with entropy

  7 passing
```

**Note:** Encrypted values appear as handles in test output. Decrypt off-chain to see actual values.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](/examples)
2. Find "EntropyEncryption" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropyEncryption");
     const contract = await ContractFactory.deploy(ENTROPY_ORACLE_ADDRESS);
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropyEncryption deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

**Important:** Constructor argument must be the EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📊 Expected Outputs

### After Basic Encryption

- `isInitialized()` returns `true`
- `getEncryptedValue()` returns encrypted value (handle)
- `ValueEncrypted` event emitted

### After Entropy-Enhanced Encryption

- `isInitialized()` returns `true`
- `getEncryptedValue()` returns entropy-enhanced encrypted value
- Value is mixed with entropy (unpredictable)
- `ValueEncryptedWithEntropy` event emitted

### After Update

- `getEncryptedValue()` returns new encrypted value
- Old value replaced with new value
- `ValueUpdated` event emitted

## ⚠️ Common Errors & Solutions

### Error: `SenderNotAllowed()`

**Cause:** Missing `FHE.allowThis()` call on encrypted value.

**Example:**
```solidity
euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
// Missing: FHE.allowThis(entropy);
euint64 result = FHE.xor(value, entropy); // ❌ Error!
```

**Solution:**
```solidity
euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
FHE.allowThis(entropy); // ✅ Required!
euint64 result = FHE.xor(value, entropy);
```

**Prevention:** Always call `FHE.allowThis()` on all encrypted values before using them.

---

### Error: `Entropy not ready`

**Cause:** Calling `encryptAndStoreWithEntropy()` before entropy is fulfilled.

**Solution:** Always check `isRequestFulfilled()` before using entropy.

---

### Error: `Invalid oracle address`

**Cause:** Wrong or zero address passed to constructor.

**Solution:** Always use the fixed EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting entropy.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestEntropy(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor argument used during verification.

**Solution:** Always use the EntropyOracle address:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

## 🔗 Related Examples

- [EntropyUserDecryption](../user-decryption-userdecryptsingle/) - Entropy-based user decryption
- [EntropyPublicDecryption](../public-decryption-publicdecryptsingle/) - Entropy-based public decryption
- [EntropyCounter](../basic-simplecounter/) - Entropy-based counter
- [Category: encryption](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/entrofhe/tree/main/examples/encryption-encryptsingle) - Source code

## 📝 License

BSD-3-Clause-Clear
