// Compatible with OpenZeppelin Contracts ^5.4.0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;


//    /$$   /$$ /$$   /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$
//   | $$  / $$| $$$ | $$ /$$__  $$| $$__  $$| $$_____/
//   |  $$/ $$/| $$$$| $$| $$  \ $$| $$  \ $$| $$
//    \  $$$$/ | $$ $$ $$| $$  | $$| $$  | $$| $$$$$
//     >$$  $$ | $$  $$$$| $$  | $$| $$  | $$| $$__/
//    /$$/\  $$| $$\  $$$| $$  | $$| $$  | $$| $$
//   | $$  \ $$| $$ \  $$|  $$$$$$/| $$$$$$$/| $$$$$$$$
//   |__/  |__/|__/  \__/ \______/ |_______/ |________/


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract VnodeTokenICO is
    ERC20,
    ERC20Burnable,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    using SafeERC20 for IERC20;

    constructor() ERC20("Vnode", "Vnode") Ownable(msg.sender) {
        uint256 totalSupply = 100000000 * 10 ** decimals();
        _mint(owner(), totalSupply);
    }

    uint256 private saleId;
    bool public saleM = true;

    struct SaleDetail {
        uint256 start;
        uint256 end;
        uint256 price; // in wei per token
        uint256 totalTokens;
        uint256 tokenSold;
        uint256 minBound;
        uint256 raisedIn;
        uint256 remainingToken;
    }

    struct UserToken {
        uint256 saleRound;
        uint256 tokenspurchased;
        uint256 createdOn;
        uint256 remainingTokens;
    }

    struct UserStaking {
        uint256 stakeAmount;
        uint256 claimed;
        uint256 lastClaimedTime;
        uint256 lockingPeriod;
        uint256 totalReward;
        uint256 rewardPerWeek;
        uint256 stakeStartTime;
    }

    mapping(uint256 => SaleDetail) public salesDetailMap;
    mapping(uint256 => mapping(address => UserToken)) public userTokenMap;
    mapping(uint256 => bool) internal saleIdMap;
    mapping(address => UserStaking) public userStakingMap;

    event BoughtTokens(address indexed to, uint256 value, uint256 saleId);
    event SaleCreated(uint256 saleId);
    event Staked(address indexed from, uint256 value, uint256 duration);
    event claimed(address indexed from, uint256 value);

    uint256 private privateSaleId;
    uint256 private publicSaleId;
    uint256 public minimumStakingAmount;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateSaleIdbyType(uint256 _saleType, uint256 _saleId) internal {
        if (_saleType == 0) {
            privateSaleId = _saleId;
        } else if (_saleType == 1) {
            publicSaleId = _saleId;
        } else {
            revert("Invalid sale type");
        }
    }

    function getSaleIdbyType(
        uint256 _saleType
    ) internal view returns (uint256) {
        uint256 _saleId = _saleType == 0 ? privateSaleId : publicSaleId;
        return _saleId;
    }

    function toggleSale() external onlyOwner {
        saleM = !saleM;
    }

    function startTokenSale(
        uint256 _saleType,
        uint256 _start,
        uint256 _end,
        uint256 _price,
        uint256 _minBound,
        uint256 _totalTokens
    ) external onlyOwner returns (uint256) {
        require(_saleType == 0 || _saleType == 1, "Invalid sale type");
        saleId++;
        updateSaleIdbyType(_saleType, saleId);
        SaleDetail memory detail;
        detail.start = _start;
        detail.end = _end;
        detail.price = _price;
        detail.minBound = _minBound;
        detail.totalTokens = _totalTokens;
        detail.remainingToken = _totalTokens;
        salesDetailMap[saleId] = detail;
        emit SaleCreated(saleId);
        return saleId;
    }

    function isActive(uint256 _saleId) public view returns (bool) {
        SaleDetail memory sale = salesDetailMap[_saleId];
        return (block.timestamp >= sale.start && // Sale has started
            block.timestamp <= sale.end && // Sale has not ended
            !saleIdMap[_saleId]); // Sale is not finalized or goal not reached
    }

    function calculateToken(
        uint256 amount,
        uint256 _rate
    ) public pure returns (uint256) {
        return (amount * 10 ** 18) / _rate;
    }

    function buyTokens(uint8 _saleType) public payable nonReentrant {
        uint256 _saleId = getSaleIdbyType(_saleType);
        require(isActive(_saleId), "Sale is not active");

        require(msg.sender != owner(), "Owner cannot buy tokens");

        require(saleM, "the sale is temporary stop");

        SaleDetail storage detail = salesDetailMap[_saleId];
        uint256 tokens;

        tokens = calculateToken(msg.value, detail.price);
        require(tokens >= detail.minBound, "Not enough tokens");
        require(
            balanceOf(owner()) >= tokens,
            "Insufficient tokenss in contract"
        );
        _transfer(owner(), msg.sender, tokens);
        // _transfer(owner(), msg.sender, 11 * 10**decimals());

        detail.raisedIn += msg.value;
        payable(owner()).transfer(msg.value);

        detail.tokenSold += tokens;
        detail.remainingToken -= tokens;

        UserToken storage utoken = userTokenMap[_saleId][msg.sender];
        utoken.saleRound = _saleId;
        utoken.createdOn = block.timestamp;
        utoken.tokenspurchased += tokens;

        emit BoughtTokens(msg.sender, tokens, _saleId);
    }

    function getBNBbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBNB() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No BNB available in contract");
        payable(owner()).transfer(balance);
    }

    function stakeTokens(
        uint256 _amount,
        uint256 _durationInDays
    ) external nonReentrant whenNotPaused {
        require(_amount > minimumStakingAmount, "Insufficient staking amount");
        _transfer(msg.sender, address(this), _amount);

        UserStaking storage staking = userStakingMap[msg.sender];

        staking.stakeAmount = _amount;
        staking.lockingPeriod = _durationInDays * 1 days;
        staking.stakeStartTime = block.timestamp;
        staking.lastClaimedTime = block.timestamp;

        if (_durationInDays == 90) {
            staking.rewardPerWeek = (_amount * 10) / 100; // 10%
        } else if (_durationInDays == 120) {
            staking.rewardPerWeek = (_amount * 15) / 100; // 15%
        } else if (_durationInDays == 180) {
            staking.rewardPerWeek = (_amount * 20) / 100; // 20%
        } else {
            revert("Invalid staking duration");
        }

        uint256 totalWeeks = _durationInDays / 7;
        staking.totalReward = staking.rewardPerWeek * totalWeeks;

        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function calculateRewards(
        address _user,
        uint256 _tokens,
        uint256 _duration
    ) internal returns (uint256) {
        UserStaking storage ustaking = userStakingMap[_user];
        uint256 rewardPercentage;

        // Determine the reward percentage based on duration
        if (_duration == 90 days) {
            rewardPercentage = 10; // 10% weekly for 90 days
        } else if (_duration == 120 days) {
            rewardPercentage = 15; // 15% weekly for 120 days
        } else if (_duration == 180 days) {
            rewardPercentage = 20; // 20% weekly for 180 days
        } else {
            revert("Invalid duration"); // Invalid duration
        }

        // Calculate weekly reward for the given duration
        uint256 weeklyReward = (_tokens * rewardPercentage) / 100; // Reward per week

        // Calculate total rewards for the entire staking period
        uint256 totalRewards = weeklyReward * (_duration / 7 days); // Duration in weeks
        ustaking.totalReward = totalRewards;
        ustaking.rewardPerWeek = weeklyReward;

        // rewardPerWeek
        return weeklyReward;
    }

    function claim() external nonReentrant whenNotPaused {
        UserStaking storage staking = userStakingMap[msg.sender];

        require(
            block.timestamp >= staking.lastClaimedTime + 7 days,
            "Claim allowed only once a week"
        );

        uint256 weeksPassed = (block.timestamp - staking.lastClaimedTime) /
            7 days;

        require(weeksPassed >= 1, "No full week passed");
        uint256 claimableReward = staking.rewardPerWeek * weeksPassed;

        uint256 remainingReward = staking.totalReward - staking.claimed;
        require(remainingReward > 0, "No rewards left to claim");

        if (claimableReward > remainingReward) {
            claimableReward = remainingReward; // cap it
        }

        require(
            balanceOf(owner()) >= claimableReward,
            "Contract has insufficient reward balance"
        );

        staking.claimed += claimableReward;
        staking.lastClaimedTime = block.timestamp;
        _transfer(owner(), msg.sender, claimableReward); // ✅ correct from contract balance
        emit claimed(msg.sender, claimableReward);
    }

    function unstake() external nonReentrant whenNotPaused {
        UserStaking storage staking = userStakingMap[msg.sender];
        require(
            block.timestamp >= staking.stakeStartTime + staking.lockingPeriod,
            "Staking period not over"
        );
        require(staking.stakeAmount > 0, "No stake found");

        uint256 amount = staking.stakeAmount;
        staking.stakeAmount = 0;

        _transfer(owner(), msg.sender, amount);
    }
}
