import { expect } from 'chai';
import { ethers } from 'hardhat';
import { deployToken, TOKEN_NAME, TOKEN_SYMBOL, CONTRACT_URI, EXTRA_INFO } from './helpers/deploy';
import { runCoreTests } from './helpers/core-tests';

describe('CMTATConfidentialLite', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATConfidentialLite');
    Object.assign(this, ctx);
  });

  runCoreTests();

  describe('decimals configuration', function () {
    it('uses configured decimals for CMTATConfidentialLite', async function () {
      const { token } = await deployToken('CMTATConfidentialLite', 3);
      expect(await token.decimals()).to.equal(3);
    });

    it('reverts with CMTAT_DecimalsTooHigh when decimals > 18', async function () {
      const [admin] = await ethers.getSigners();
      const factory = await ethers.getContractFactory('CMTATConfidentialLite');
      await expect(
        factory.deploy(TOKEN_NAME, TOKEN_SYMBOL, CONTRACT_URI, 19, admin.address, EXTRA_INFO)
      ).to.be.revertedWithCustomError(factory, 'CMTAT_DecimalsTooHigh').withArgs(19);
    });
  });
});
