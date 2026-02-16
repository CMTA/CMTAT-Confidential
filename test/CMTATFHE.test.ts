import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import hre, { ethers, fhevm } from 'hardhat';

const name = 'CMTATFHE Token';
const symbol = 'CMTATFHE';
const contractURI = 'https://example.com/metadata';
const tokenId = 'TOKEN-001';
const terms = {
  name: 'Terms Document',
  uri: 'https://example.com/terms',
  documentHash: ethers.ZeroHash,
};
const information = 'Test token information';

// Role constants (must match contract)
const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('MINTER_ROLE'));
const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('BURNER_ROLE'));
const PAUSER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('PAUSER_ROLE'));
const ENFORCER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('ENFORCER_ROLE'));
const DEFAULT_ADMIN_ROLE = ethers.ZeroHash;

describe('CMTATFHE', function () {
  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    const [admin, minter, burner, pauser, enforcer, holder, recipient] = accounts;

    this.admin = admin;
    this.minter = minter;
    this.burner = burner;
    this.pauser = pauser;
    this.enforcer = enforcer;
    this.holder = holder;
    this.recipient = recipient;
    this.accounts = accounts.slice(7);

    // Deploy the token
    const extraInfoAttributes = {
      tokenId: tokenId,
      terms: terms,
      information: information,
    };

    this.token = await ethers.deployContract('CMTATFHE', [
      name,
      symbol,
      contractURI,
      admin.address,
      extraInfoAttributes,
    ]);

    // Grant roles
    await this.token.connect(admin).grantRole(MINTER_ROLE, minter.address);
    await this.token.connect(admin).grantRole(BURNER_ROLE, burner.address);
    await this.token.connect(admin).grantRole(PAUSER_ROLE, pauser.address);
    await this.token.connect(admin).grantRole(ENFORCER_ROLE, enforcer.address);
  });

  describe('constructor', function () {
    it('sets the name', async function () {
      expect(await this.token.name()).to.equal(name);
    });

    it('sets the symbol', async function () {
      expect(await this.token.symbol()).to.equal(symbol);
    });

    it('sets the contractURI', async function () {
      expect(await this.token.contractURI()).to.equal(contractURI);
    });

    it('sets decimals to 6', async function () {
      expect(await this.token.decimals()).to.equal(6);
    });

    it('grants DEFAULT_ADMIN_ROLE to admin', async function () {
      expect(await this.token.hasRole(DEFAULT_ADMIN_ROLE, this.admin.address)).to.be.true;
    });
  });

  describe('access control', function () {
    it('admin can grant roles', async function () {
      const newMinter = this.accounts[0];
      await this.token.connect(this.admin).grantRole(MINTER_ROLE, newMinter.address);
      expect(await this.token.hasRole(MINTER_ROLE, newMinter.address)).to.be.true;
    });

    it('non-admin cannot grant roles', async function () {
      const newMinter = this.accounts[0];
      await expect(
        this.token.connect(this.holder).grantRole(MINTER_ROLE, newMinter.address)
      ).to.be.reverted;
    });
  });

  describe('mint', function () {
    it('minter can mint tokens', async function () {
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        balanceHandle,
        this.token.target,
        this.holder
      );
      expect(balance).to.equal(1000);
    });

    it('non-minter cannot mint tokens', async function () {
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(1000)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['mint(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.reverted;
    });

    it('cannot mint to frozen address', async function () {
      // Freeze the holder
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await expect(
        this.token
          .connect(this.minter)
          ['mint(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('cannot mint when contract is deactivated', async function () {
      // Pause and deactivate
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await expect(
        this.token
          .connect(this.minter)
          ['mint(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  describe('burn', function () {
    beforeEach(async function () {
      // Mint some tokens first
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('burner can burn tokens', async function () {
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.burner.address)
        .add64(500)
        .encrypt();

      await this.token
        .connect(this.burner)
        ['burn(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        balanceHandle,
        this.token.target,
        this.holder
      );
      expect(balance).to.equal(500);
    });

    it('non-burner cannot burn tokens', async function () {
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['burn(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.reverted;
    });

    it('cannot burn from frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.burner.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.burner)
          ['burn(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  describe('pause', function () {
    beforeEach(async function () {
      // Mint some tokens first
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('pauser can pause', async function () {
      await this.token.connect(this.pauser).pause();
      expect(await this.token.paused()).to.be.true;
    });

    it('pauser can unpause', async function () {
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.pauser).unpause();
      expect(await this.token.paused()).to.be.false;
    });

    it('non-pauser cannot pause', async function () {
      await expect(this.token.connect(this.holder).pause()).to.be.reverted;
    });

    it('transfers are blocked when paused', async function () {
      await this.token.connect(this.pauser).pause();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(100)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['confidentialTransfer(address,bytes32,bytes)'](
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('mint is allowed when paused', async function () {
      await this.token.connect(this.pauser).pause();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(500)
        .encrypt();

      // Mint should still work while paused
      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const balanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      const balance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        balanceHandle,
        this.token.target,
        this.recipient
      );
      expect(balance).to.equal(500);
    });

    it('burn is allowed when paused', async function () {
      await this.token.connect(this.pauser).pause();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.burner.address)
        .add64(500)
        .encrypt();

      // Burn should still work while paused
      await this.token
        .connect(this.burner)
        ['burn(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        balanceHandle,
        this.token.target,
        this.holder
      );
      expect(balance).to.equal(500);
    });

    it('operator transfers are blocked when paused', async function () {
      // Set up operator first
      const expirationTimestamp = Math.floor(Date.now() / 1000) + 86400;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, expirationTimestamp);

      // Then pause
      await this.token.connect(this.pauser).pause();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.accounts[0].address)
        .add64(100)
        .encrypt();

      await expect(
        this.token
          .connect(this.accounts[0])
          ['confidentialTransferFrom(address,address,bytes32,bytes)'](
            this.holder.address,
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  describe('freeze', function () {
    beforeEach(async function () {
      // Mint some tokens to holder
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('enforcer can freeze an address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      expect(await this.token.isFrozen(this.holder.address)).to.be.true;
    });

    it('enforcer can unfreeze an address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      expect(await this.token.isFrozen(this.holder.address)).to.be.false;
    });

    it('non-enforcer cannot freeze', async function () {
      await expect(
        this.token.connect(this.holder).setAddressFrozen(this.recipient.address, true)
      ).to.be.reverted;
    });

    it('frozen address cannot transfer', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(100)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['confidentialTransfer(address,bytes32,bytes)'](
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('cannot transfer to frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.recipient.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(100)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['confidentialTransfer(address,bytes32,bytes)'](
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  describe('forcedTransfer', function () {
    beforeEach(async function () {
      // Mint some tokens to holder
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('enforcer can force transfer from frozen address', async function () {
      // Freeze the holder first (required for forcedTransfer)
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      await this.token
        .connect(this.enforcer)
        ['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address,
          this.recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const recipientBalanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      const recipientBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        recipientBalanceHandle,
        this.token.target,
        this.recipient
      );
      expect(recipientBalance).to.equal(500);
    });

    it('cannot force transfer from non-frozen address', async function () {
      // Holder is NOT frozen
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.enforcer)
          ['forcedTransfer(address,address,bytes32,bytes)'](
            this.holder.address,
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('non-enforcer cannot force transfer', async function () {
      // Freeze the holder first
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['forcedTransfer(address,address,bytes32,bytes)'](
            this.holder.address,
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.reverted;
    });

    it('cannot force transfer to address(0)', async function () {
      // Freeze the holder first
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.enforcer)
          ['forcedTransfer(address,address,bytes32,bytes)'](
            this.holder.address,
            ethers.ZeroAddress,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_AddressZeroNotAllowed');
    });

    it('enforcer can force transfer even when contract is deactivated', async function () {
      // Freeze the holder first
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      // Pause and deactivate the contract
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      // Forced transfer should still work even when deactivated
      await this.token
        .connect(this.enforcer)
        ['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address,
          this.recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const recipientBalanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      const recipientBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        recipientBalanceHandle,
        this.token.target,
        this.recipient
      );
      expect(recipientBalance).to.equal(500);
    });
  });

  describe('forcedBurn', function () {
    beforeEach(async function () {
      // Mint some tokens to holder
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('enforcer can force burn from frozen address', async function () {
      // Freeze the holder first (required for forcedBurn)
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      await this.token
        .connect(this.enforcer)
        ['forcedBurn(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      // Unfreeze to check balance
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);

      const holderBalanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const holderBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        holderBalanceHandle,
        this.token.target,
        this.holder
      );
      expect(holderBalance).to.equal(500);
    });

    it('enforcer can force burn all tokens from frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.enforcer)
        ['forcedBurn(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);

      const holderBalanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const holderBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        holderBalanceHandle,
        this.token.target,
        this.holder
      );
      expect(holderBalance).to.equal(0);
    });

    it('cannot force burn from non-frozen address', async function () {
      // Holder is NOT frozen
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.enforcer)
          ['forcedBurn(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('non-enforcer cannot force burn', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(500)
        .encrypt();

      await expect(
        this.token
          .connect(this.holder)
          ['forcedBurn(address,bytes32,bytes)'](
            this.holder.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.reverted;
    });

    it('enforcer can force burn even when contract is deactivated', async function () {
      // Freeze the holder first
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      // Pause and deactivate the contract
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(500)
        .encrypt();

      // Forced burn should still work even when deactivated
      await this.token
        .connect(this.enforcer)
        ['forcedBurn(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);

      const holderBalanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const holderBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        holderBalanceHandle,
        this.token.target,
        this.holder
      );
      expect(holderBalance).to.equal(500);
    });

    it('force burn with amount exceeding balance burns 0', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.enforcer.address)
        .add64(2000) // More than balance
        .encrypt();

      await this.token
        .connect(this.enforcer)
        ['forcedBurn(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);

      // Balance should remain unchanged (FHE burns 0 silently on insufficient balance)
      const holderBalanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const holderBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        holderBalanceHandle,
        this.token.target,
        this.holder
      );
      expect(holderBalance).to.equal(1000);
    });
  });

  describe('transfer', function () {
    beforeEach(async function () {
      // Mint some tokens to holder
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('holder can transfer tokens', async function () {
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(400)
        .encrypt();

      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const recipientBalanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      const recipientBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        recipientBalanceHandle,
        this.token.target,
        this.recipient
      );
      expect(recipientBalance).to.equal(400);

      const holderBalanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const holderBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        holderBalanceHandle,
        this.token.target,
        this.holder
      );
      expect(holderBalance).to.equal(600);
    });

    it('transfer with insufficient balance transfers 0', async function () {
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(2000) // More than balance
        .encrypt();

      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      // Recipient should have 0 (transfer failed silently due to FHE)
      const recipientBalanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      const recipientBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        recipientBalanceHandle,
        this.token.target,
        this.recipient
      );
      expect(recipientBalance).to.equal(0);

      // Holder should still have original balance
      const holderBalanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      const holderBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        holderBalanceHandle,
        this.token.target,
        this.holder
      );
      expect(holderBalance).to.equal(1000);
    });
  });

  describe('operator', function () {
    beforeEach(async function () {
      // Mint some tokens to holder
      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.minter.address)
        .add64(1000)
        .encrypt();

      await this.token
        .connect(this.minter)
        ['mint(address,bytes32,bytes)'](
          this.holder.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );
    });

    it('holder can set operator', async function () {
      const expirationTimestamp = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, expirationTimestamp);
      expect(await this.token.isOperator(this.holder.address, this.accounts[0].address)).to.be.true;
    });

    it('operator can transfer on behalf of holder', async function () {
      const expirationTimestamp = Math.floor(Date.now() / 1000) + 86400;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, expirationTimestamp);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.accounts[0].address)
        .add64(300)
        .encrypt();

      await this.token
        .connect(this.accounts[0])
        ['confidentialTransferFrom(address,address,bytes32,bytes)'](
          this.holder.address,
          this.recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof
        );

      const recipientBalanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      const recipientBalance = await fhevm.userDecryptEuint(
        FhevmType.euint64,
        recipientBalanceHandle,
        this.token.target,
        this.recipient
      );
      expect(recipientBalance).to.equal(300);
    });

    it('expired operator cannot transfer', async function () {
      const expirationTimestamp = Math.floor(Date.now() / 1000) - 1; // Already expired
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, expirationTimestamp);

      const encryptedInput = await fhevm
        .createEncryptedInput(this.token.target, this.accounts[0].address)
        .add64(300)
        .encrypt();

      await expect(
        this.token
          .connect(this.accounts[0])
          ['confidentialTransferFrom(address,address,bytes32,bytes)'](
            this.holder.address,
            this.recipient.address,
            encryptedInput.handles[0],
            encryptedInput.inputProof
          )
      ).to.be.revertedWithCustomError(this.token, 'ERC7984UnauthorizedSpender');
    });
  });
});
