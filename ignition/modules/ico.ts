import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


module.exports = buildModule("LockModule", (m) => {
  const lock = m.contract("VnodeTokenICO", []);
  return { lock };
});


// Explorer: https://testnet.bscscan.com/address/0x1b9d2864b97F402c6eB412d4bDffb1088070F7F3#code