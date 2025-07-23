require("@nomicfoundation/hardhat-toolbox");
require("hardhat-contract-sizer");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
   solidity: {
    version: '0.8.30',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: 'prague'
    }
  },contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    //only: [':ERC20$'],
}

  };
