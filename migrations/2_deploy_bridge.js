const Bridge = artifacts.require("Bridge");

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await deployer.deploy(Bridge, "0xE592427A0AEce92De3Edee1F18E0157C05861564", "0x000000883B88Ab8f172Bf5422c97a56398BDf8d8");

        const bridge = await Bridge.deployed();

        await bridge.addToken("1", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270");
        await bridge.addToken("2", "0xc2132d05d31c914a87c6611c10748aeb04b58e8f");
    });        
}