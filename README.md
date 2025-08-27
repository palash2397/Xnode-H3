# 🏦 Xnode Exchange

Xnode Exchange is a decentralized  built on Solidity and deployed using Hardhat. , 
---

## 📦 Tech Stack

- Solidity (v0.8.x)
- Hardhat — Development framework
- Ethers.js — For contract interaction
- Chai/Mocha — For testing
- Hardhat Ignition — Deployment orchestration
- dotenv — For environment variables

---

## 📁 Project Structure

```
Xnode-H3/
├── contracts/            # Solidity smart contracts
├── test/                 # Unit tests using Chai
├── scripts/              # Optional deploy or utility scripts
├── ignition/             # Hardhat Ignition deployment modules
├── .env                  # Private env variables (not committed)
├── .env.example          # Sample file showing env variable names
├── hardhat.config.js     # Hardhat config
├── package.json          # Dependencies and scripts
```

---

## ⚙️ Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/palash2397/Xnode-H3.git
cd Xnode-H3
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Setup Environment Variables

Create a `.env` file in the root directory.  
All required credentials and variable names are listed in the `.env.example` file.

```bash
cp .env.example .env
```

> ⚠️ Never commit your `.env` file — it’s excluded via `.gitignore`.

---

## 🚀 Usage Guide

### ✅ Compile Contracts

```bash
npx hardhat compile
```

### 🧪 Run Tests

```bash
npx hardhat test
```

With gas report:

```bash
REPORT_GAS=true 
```

### 🌐 Run Local Hardhat Node

```bash
npx hardhat node
```

### 📦 Deploy Using Hardhat Ignition

```bash
npx hardhat ignition deploy ./ignition/modules/Reward.js
```





