import { FhevmType } from '@fhevm/hardhat-plugin';
import { ethers, fhevm } from 'hardhat';

// ─── Token metadata ───────────────────────────────────────────────────────────

export const TOKEN_NAME = 'CMTATFHE Token';
export const TOKEN_SYMBOL = 'CMTATFHE';
export const CONTRACT_URI = 'https://example.com/metadata';

export const EXTRA_INFO = {
  tokenId: 'TOKEN-001',
  terms: {
    name: 'Terms Document',
    uri: 'https://example.com/terms',
    documentHash: ethers.ZeroHash,
  },
  information: 'Test token information',
};

// ─── Role constants ───────────────────────────────────────────────────────────

export const DEFAULT_ADMIN_ROLE = ethers.ZeroHash;
export const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('MINTER_ROLE'));
export const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('BURNER_ROLE'));
export const PAUSER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('PAUSER_ROLE'));
export const ENFORCER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('ENFORCER_ROLE'));
export const OBSERVER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('OBSERVER_ROLE'));
export const SUPPLY_OBSERVER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('SUPPLY_OBSERVER_ROLE'));

// ─── Deploy helper ────────────────────────────────────────────────────────────

/**
 * Deploys the given contract (CMTATFHE or CMTATFHELite), grants standard roles,
 * and returns the token + named signers.
 *
 * Signer layout (matches all test files):
 *   [0] admin  [1] minter  [2] burner  [3] pauser  [4] enforcer
 *   [5] holder [6] recipient  [7..] accounts (extra)
 */
export async function deployToken(contractName: string) {
  const signers = await ethers.getSigners();
  const [admin, minter, burner, pauser, enforcer, holder, recipient] = signers;
  const accounts = signers.slice(7);

  const token = await ethers.deployContract(contractName, [
    TOKEN_NAME,
    TOKEN_SYMBOL,
    CONTRACT_URI,
    admin.address,
    EXTRA_INFO,
  ]);

  await token.connect(admin).grantRole(MINTER_ROLE, minter.address);
  await token.connect(admin).grantRole(BURNER_ROLE, burner.address);
  await token.connect(admin).grantRole(PAUSER_ROLE, pauser.address);
  await token.connect(admin).grantRole(ENFORCER_ROLE, enforcer.address);

  return { token, admin, minter, burner, pauser, enforcer, holder, recipient, accounts };
}

// ─── FHE helpers ─────────────────────────────────────────────────────────────

export async function encryptAmount(tokenAddress: string, signerAddress: string, amount: number) {
  return fhevm
    .createEncryptedInput(tokenAddress, signerAddress)
    .add64(amount)
    .encrypt();
}

export async function decryptBalance(tokenAddress: string, handle: bigint, signer: any): Promise<bigint> {
  return fhevm.userDecryptEuint(FhevmType.euint64, handle, tokenAddress, signer);
}

export async function mint(token: any, minter: any, to: any, amount: number) {
  const enc = await encryptAmount(token.target, minter.address, amount);
  await token.connect(minter)['mint(address,bytes32,bytes)'](to.address, enc.handles[0], enc.inputProof);
}
