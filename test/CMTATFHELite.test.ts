import { deployToken } from './helpers/deploy';
import { runCoreTests } from './helpers/core-tests';

describe('CMTATFHELite', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATFHELite');
    Object.assign(this, ctx);
  });

  runCoreTests();
});
