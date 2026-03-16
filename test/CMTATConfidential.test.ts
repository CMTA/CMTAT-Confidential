import { expect } from 'chai';
import { ethers } from 'hardhat';
import { deployToken, TOKEN_DECIMALS, TOKEN_NAME, TOKEN_SYMBOL, CONTRACT_URI, EXTRA_INFO } from './helpers/deploy';
import { runCoreTests } from './helpers/core-tests';

describe('CMTATConfidential', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATConfidential');
    Object.assign(this, ctx);
  });

  runCoreTests();

  describe('decimals configuration', function () {
    it('uses default configured decimals from deploy helper', async function () {
      const { token } = await deployToken('CMTATConfidential');
      expect(await token.decimals()).to.equal(TOKEN_DECIMALS);
    });

    it('supports deploying with 0 decimals', async function () {
      const { token } = await deployToken('CMTATConfidential', 0);
      expect(await token.decimals()).to.equal(0);
    });

    it('supports deploying with 18 decimals', async function () {
      const { token } = await deployToken('CMTATConfidential', 18);
      expect(await token.decimals()).to.equal(18);
    });

    it('reverts with CMTAT_DecimalsTooHigh when decimals > 18', async function () {
      const [admin] = await ethers.getSigners();
      const factory = await ethers.getContractFactory('CMTATConfidential');
      await expect(
        factory.deploy(TOKEN_NAME, TOKEN_SYMBOL, CONTRACT_URI, 19, admin.address, EXTRA_INFO)
      ).to.be.revertedWithCustomError(factory, 'CMTAT_DecimalsTooHigh').withArgs(19);
    });
  });
});
