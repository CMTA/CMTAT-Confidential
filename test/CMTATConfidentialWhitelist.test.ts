import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  deployToken,
  mint,
  encryptAmount,
  decryptBalance,
  TOKEN_NAME,
  TOKEN_SYMBOL,
  CONTRACT_URI,
  EXTRA_INFO,
} from './helpers/deploy';
import { runCoreTests } from './helpers/core-tests';

const ALLOWLIST_ROLE = ethers.keccak256(
  ethers.toUtf8Bytes('ALLOWLIST_ROLE')
);
const ERC7943_FUNGIBLE_INTERFACE_ID = '0x3edbb4c4';

describe('CMTATConfidentialWhitelist', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATConfidentialWhitelist');
    Object.assign(this, ctx);
    await this.token
      .connect(this.admin)
      .grantRole(ALLOWLIST_ROLE, this.admin.address);
  });

  runCoreTests();

  describe('whitelist', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('allows transfers when allowlist is disabled', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          enc.handles[0],
          enc.inputProof
        );

      const recipientHandle = await this.token.confidentialBalanceOf(
        this.recipient.address
      );
      expect(
        await decryptBalance(this.token.target, recipientHandle, this.recipient)
      ).to.equal(100n);
    });

    it('blocks transfer when allowlist is enabled and recipient is not allowlisted', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);

      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token
          .connect(this.holder)
          ['confidentialTransfer(address,bytes32,bytes)'](
            this.recipient.address,
            enc.handles[0],
            enc.inputProof
          )
      ).to.be.revertedWithCustomError(
        this.token,
        'ERC7943CannotTransfer'
      );
    });

    it('allows transfer when allowlist is enabled and both sides are allowlisted', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);
      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.holder.address, true);
      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.recipient.address, true);

      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          enc.handles[0],
          enc.inputProof
        );

      const recipientHandle = await this.token.confidentialBalanceOf(
        this.recipient.address
      );
      expect(
        await decryptBalance(this.token.target, recipientHandle, this.recipient)
      ).to.equal(100n);
    });

    it('blocks transfer when allowlist is enabled and sender is not allowlisted', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);
      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.recipient.address, true);

      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token
          .connect(this.holder)
          ['confidentialTransfer(address,bytes32,bytes)'](
            this.recipient.address,
            enc.handles[0],
            enc.inputProof
          )
      ).to.be.revertedWithCustomError(
        this.token,
        'ERC7943CannotTransfer'
      );
    });

    it('applies to operator transferFrom as well', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);
      const exp = BigInt((await ethers.provider.getBlock('latest'))!.timestamp + 3600);
      await this.token
        .connect(this.holder)
        .setOperator(this.accounts[0].address, exp);

      const enc = await encryptAmount(this.token.target, this.accounts[0].address, 100);
      await expect(
        this.token
          .connect(this.accounts[0])
          ['confidentialTransferFrom(address,address,bytes32,bytes)'](
            this.holder.address,
            this.recipient.address,
            enc.handles[0],
            enc.inputProof
          )
      ).to.be.revertedWithCustomError(
        this.token,
        'ERC7943CannotTransfer'
      );
    });

    it('only whitelist manager can manage whitelist', async function () {
      await expect(
        this.token
          .connect(this.holder)
          .setAddressAllowlist(this.recipient.address, true)
      ).to.be.reverted;
    });

    it('allowlist toggle from CMTAT disables enforcement when false', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);

      const blocked = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token
          .connect(this.holder)
          ['confidentialTransfer(address,bytes32,bytes)'](
            this.recipient.address,
            blocked.handles[0],
            blocked.inputProof
          )
      ).to.be.revertedWithCustomError(
        this.token,
        'ERC7943CannotTransfer'
      );

      await this.token.connect(this.admin).enableAllowlist(false);
      const allowed = await encryptAmount(this.token.target, this.holder.address, 100);
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          allowed.handles[0],
          allowed.inputProof
        );
    });

    it('exposes ERC-7943 view checks', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);

      expect(await this.token.canSend(this.holder.address)).to.equal(false);
      expect(await this.token.canReceive(this.recipient.address)).to.equal(false);
      expect(
        await this.token.canTransfer(this.holder.address, this.recipient.address, 1)
      ).to.equal(false);

      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.holder.address, true);
      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.recipient.address, true);

      expect(await this.token.canSend(this.holder.address)).to.equal(true);
      expect(await this.token.canReceive(this.recipient.address)).to.equal(true);
      expect(
        await this.token.canTransfer(this.holder.address, this.recipient.address, 1)
      ).to.equal(true);
    });

    it('advertises ERC-7943 fungible support through ERC-165', async function () {
      expect(
        await this.token.supportsInterface(ERC7943_FUNGIBLE_INTERFACE_ID)
      ).to.equal(true);
    });

    it('keeps canTransfer amount-agnostic for confidential amounts', async function () {
      await this.token.connect(this.admin).enableAllowlist(true);
      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.holder.address, true);
      await this.token
        .connect(this.admin)
        .setAddressAllowlist(this.recipient.address, true);

      expect(
        await this.token.canTransfer(this.holder.address, this.recipient.address, 1)
      ).to.equal(true);
      expect(
        await this.token.canTransfer(
          this.holder.address,
          this.recipient.address,
          ethers.MaxUint256
        )
      ).to.equal(true);
    });
  });

  describe('decimals configuration', function () {
    it('uses configured decimals for CMTATConfidentialWhitelist', async function () {
      const { token } = await deployToken('CMTATConfidentialWhitelist', 3);
      expect(await token.decimals()).to.equal(3);
    });

    it('reverts with CMTAT_DecimalsTooHigh when decimals > 18', async function () {
      const [admin] = await ethers.getSigners();
      const factory = await ethers.getContractFactory(
        'CMTATConfidentialWhitelist'
      );
      await expect(
        factory.deploy(
          TOKEN_NAME,
          TOKEN_SYMBOL,
          CONTRACT_URI,
          19,
          admin.address,
          EXTRA_INFO
        )
      )
        .to.be.revertedWithCustomError(factory, 'CMTAT_DecimalsTooHigh')
        .withArgs(19);
    });
  });
});
