import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';
import { deployToken, MINTER_ROLE, SUPPLY_OBSERVER_ROLE, TOKEN_DECIMALS, mint, decryptBalance } from './helpers/deploy';

describe('ERC7984TotalSupplyViewModule', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATFHE');
    Object.assign(this, ctx);

    // supplyManager holds SUPPLY_OBSERVER_ROLE
    this.supplyManager = this.accounts[0];
    this.observer = this.accounts[1];
    this.observer2 = this.accounts[2];
    this.other = this.accounts[3];

    await this.token.connect(this.admin).grantRole(SUPPLY_OBSERVER_ROLE, this.supplyManager.address);
  });

  async function decryptTotalSupply(token: any, signer: any): Promise<bigint> {
    const handle = await token.confidentialTotalSupply();
    return fhevm.userDecryptEuint(FhevmType.euint64, handle, token.target, signer);
  }

  // ─── addTotalSupplyObserver ─────────────────────────────────────────────

  describe('addTotalSupplyObserver', function () {
    it('supply manager can add an observer', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
      expect(await this.token.totalSupplyObservers()).to.include(this.observer.address);
    });

    it('emits TotalSupplyObserverAdded', async function () {
      await expect(
        this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address)
      )
        .to.emit(this.token, 'TotalSupplyObserverAdded')
        .withArgs(this.observer.address, this.supplyManager.address);
    });

    it('unauthorized caller cannot add observer', async function () {
      await expect(
        this.token.connect(this.other).addTotalSupplyObserver(this.observer.address)
      ).to.be.reverted;
    });

    it('reverts AlreadyObserver on duplicate', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
      await expect(
        this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address)
      ).to.be.revertedWithCustomError(this.token, 'ERC7984TotalSupplyViewModule_AlreadyObserver');
    });

    it('reverts on zero address observer', async function () {
      await expect(
        this.token.connect(this.supplyManager).addTotalSupplyObserver(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(this.token, 'ERC7984TotalSupplyViewModule_ZeroAddressObserver');
    });

    it('grants ACL immediately on existing total supply handle', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
      const supply = await decryptTotalSupply(this.token, this.observer);
      expect(supply).to.equal(1000n);
    });

    it('does not grant ACL when total supply not yet initialized', async function () {
      // No mint yet — handle not initialized, no ACL granted at add time
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
      // After first mint, _update re-grants ACL
      await mint(this.token, this.minter, this.holder, 500);
      const supply = await decryptTotalSupply(this.token, this.observer);
      expect(supply).to.equal(500n);
    });
  });

  // ─── removeTotalSupplyObserver ──────────────────────────────────────────

  describe('removeTotalSupplyObserver', function () {
    beforeEach(async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
    });

    it('supply manager can remove an observer', async function () {
      await this.token.connect(this.supplyManager).removeTotalSupplyObserver(this.observer.address);
      expect(await this.token.totalSupplyObservers()).to.not.include(this.observer.address);
    });

    it('emits TotalSupplyObserverRemoved', async function () {
      await expect(
        this.token.connect(this.supplyManager).removeTotalSupplyObserver(this.observer.address)
      )
        .to.emit(this.token, 'TotalSupplyObserverRemoved')
        .withArgs(this.observer.address, this.supplyManager.address);
    });

    it('unauthorized caller cannot remove observer', async function () {
      await expect(
        this.token.connect(this.other).removeTotalSupplyObserver(this.observer.address)
      ).to.be.reverted;
    });

    it('reverts NotObserver when address is not registered', async function () {
      await expect(
        this.token.connect(this.supplyManager).removeTotalSupplyObserver(this.other.address)
      ).to.be.revertedWithCustomError(this.token, 'ERC7984TotalSupplyViewModule_NotObserver');
    });

    it('swap-and-pop preserves remaining observers', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer2.address);
      await this.token.connect(this.supplyManager).removeTotalSupplyObserver(this.observer.address);
      const observers = await this.token.totalSupplyObservers();
      expect(observers).to.not.include(this.observer.address);
      expect(observers).to.include(this.observer2.address);
    });
  });

  // ─── _update: re-grant ACL on mint / burn ───────────────────────────────

  describe('_update: ACL re-granted after mint and burn', function () {
    beforeEach(async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
    });

    it('observer gets ACL on total supply after mint', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      const supply = await decryptTotalSupply(this.token, this.observer);
      expect(supply).to.equal(1000n);
    });

    it('observer gets ACL on updated total supply after second mint', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await mint(this.token, this.minter, this.holder, 500);
      const supply = await decryptTotalSupply(this.token, this.observer);
      expect(supply).to.equal(1500n);
    });

    it('observer gets ACL on updated total supply after burn', async function () {
      await mint(this.token, this.minter, this.holder, 1000);

      const enc = await fhevm
        .createEncryptedInput(this.token.target, this.burner.address)
        .add64(300)
        .encrypt();
      await this.token.connect(this.burner)['burn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );

      const supply = await decryptTotalSupply(this.token, this.observer);
      expect(supply).to.equal(700n);
    });

    it('observer does NOT get ACL re-grant on regular transfer (supply unchanged)', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      // Observer already has ACL from the mint above

      const enc = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(200)
        .encrypt();
      await this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
        this.recipient.address, enc.handles[0], enc.inputProof
      );

      // Supply handle did not change — observer still has access from the mint ACL
      const supply = await decryptTotalSupply(this.token, this.observer);
      expect(supply).to.equal(1000n);
    });

    it('multiple observers all get ACL on mint', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer2.address);
      await mint(this.token, this.minter, this.holder, 800);

      const supply1 = await decryptTotalSupply(this.token, this.observer);
      const supply2 = await decryptTotalSupply(this.token, this.observer2);
      expect(supply1).to.equal(800n);
      expect(supply2).to.equal(800n);
    });
  });

  // ─── totalSupplyObservers view ──────────────────────────────────────────

  describe('totalSupplyObservers', function () {
    it('returns empty array when no observers', async function () {
      expect(await this.token.totalSupplyObservers()).to.deep.equal([]);
    });

    it('returns all registered observers', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer.address);
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.observer2.address);
      const observers = await this.token.totalSupplyObservers();
      expect(observers).to.include(this.observer.address);
      expect(observers).to.include(this.observer2.address);
      expect(observers.length).to.equal(2);
    });
  });

  // ─── CMTATFHELite does not have ERC7984TotalSupplyViewModule ────────────

  describe('CMTATFHELite absence', function () {
    it('CMTATFHELite does not expose totalSupplyObservers', async function () {
      const lite = await ethers.deployContract('CMTATFHELite', [
        'Lite', 'LITE', 'https://example.com', TOKEN_DECIMALS, this.admin.address,
        { tokenId: '', terms: { name: '', uri: '', documentHash: ethers.ZeroHash }, information: '' },
      ]);
      expect((lite as any).totalSupplyObservers).to.be.undefined;
    });
  });
});
