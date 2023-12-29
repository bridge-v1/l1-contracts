const HDWalletProvider = require('@truffle/hdwallet-provider');

const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  plugins: ['truffle-plugin-verify'],

  api_keys: {
    bscscan: '',
    polygonscan: '',
    etherscan: ''
  },

  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    polygon: {
      provider: () => new HDWalletProvider(mnemonic, `https://rpc.ankr.com/polygon`),
      network_id: 137,
      gasPrice: 120000000000
    }
  },

  mocha: {
     timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.8.20",
    }
  }
};
