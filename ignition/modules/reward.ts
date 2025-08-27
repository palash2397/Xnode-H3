import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


module.exports = buildModule("LockModule", (m) => {
  const lock = m.contract("NodeRewards", ["0x1b9d2864b97F402c6eB412d4bDffb1088070F7F3"]);
  return { lock };
});


//  Explorer: https://testnet.bscscan.com/address/0x122B8a495443fe5795E61978372730AEbC330f1d#code
// Explorer: https://testnet.bscscan.com/address/0xe56a19eCf7E8fE9DD6445Ce7822a726a68Ff057D#code