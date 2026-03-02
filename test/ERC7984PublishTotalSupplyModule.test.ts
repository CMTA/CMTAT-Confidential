import { expect } from 'chai';
import { ethers } from 'hardhat';
import { deployToken, SUPPLY_OBSERVER_ROLE, SUPPLY_PUBLISHER_ROLE, mint } from './helpers/deploy';

/**
 * Tests for ERC7984PublishTotalSupplyModule.
 *
 * publishTotalSupply is part of CMTATFHEBase, so it is available on both
 * CMTATFHE (full) and CMTATFHELite (lite).
 */
describe('ERC7984PublishTotalSupplyModule', function () {
  beforeEach(async function () {
    const allSigners = await ethers.getSigners();
    const [, , , , , , , supplyManager, other] = allSigners;

    const ctx = await deployToken('CMTATFHE');
    this.token = ctx.token;
    this.admin = ctx.admin;
    this.minter = ctx.minter;
    this.holder = ctx.holder;
    this.supplyManager = supplyManager;
    this.other = other;

    await this.token.connect(this.admin).grantRole(SUPPLY_PUBLISHER_ROLE, supplyManager.address);
  });

  // ─── CMTATFHE ────────────────────────────────────────────────────────────

  describe('on CMTATFHE', function () {
    it('supply manager can call publishTotalSupply', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await expect(this.token.connect(this.supplyManager).publishTotalSupply())
        .to.emit(this.token, 'TotalSupplyPublished')
        .withArgs(this.supplyManager.address);
    });

    it('observer role alone cannot call publishTotalSupply', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.admin).grantRole(SUPPLY_OBSERVER_ROLE, this.other.address);
      await expect(this.token.connect(this.other).publishTotalSupply()).to.be.reverted;
    });

    it('reverts when total supply handle is uninitialized', async function () {
      await expect(
        this.token.connect(this.supplyManager).publishTotalSupply()
      ).to.be.revertedWithCustomError(this.token, 'ERC7984PublishTotalSupplyModule_TotalSupplyNotInitialized');
    });

    it('unauthorized caller cannot call publishTotalSupply', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await expect(this.token.connect(this.other).publishTotalSupply()).to.be.reverted;
    });
  });

  // ─── CMTATFHELite ─────────────────────────────────────────────────────────

  describe('on CMTATFHELite', function () {
    beforeEach(async function () {
      const liteCtx = await deployToken('CMTATFHELite');
      this.lite = liteCtx.token;
      this.liteMinter = liteCtx.minter;
      this.liteHolder = liteCtx.holder;
      this.liteAdmin = liteCtx.admin;

      await this.lite.connect(this.liteAdmin).grantRole(SUPPLY_PUBLISHER_ROLE, this.supplyManager.address);
    });

    it('supply manager can call publishTotalSupply on CMTATFHELite', async function () {
      await mint(this.lite, this.liteMinter, this.liteHolder, 500);
      await expect(this.lite.connect(this.supplyManager).publishTotalSupply())
        .to.emit(this.lite, 'TotalSupplyPublished')
        .withArgs(this.supplyManager.address);
    });

    it('observer role alone cannot call publishTotalSupply on CMTATFHELite', async function () {
      await mint(this.lite, this.liteMinter, this.liteHolder, 500);
      await this.lite.connect(this.liteAdmin).grantRole(SUPPLY_OBSERVER_ROLE, this.other.address);
      await expect(this.lite.connect(this.other).publishTotalSupply()).to.be.reverted;
    });

    it('unauthorized caller cannot call publishTotalSupply on CMTATFHELite', async function () {
      await mint(this.lite, this.liteMinter, this.liteHolder, 500);
      await expect(this.lite.connect(this.other).publishTotalSupply()).to.be.reverted;
    });
  });
});
