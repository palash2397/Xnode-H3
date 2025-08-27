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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract NodeRewards is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken; // Token used for rewards

    struct NodeInfo {
        string nodeId;
        address user;
        uint256 planId;
        uint256 startTime;
        uint256 endTime;
        uint256 lastClaimed;
        bool active;
    }

    // reward per plan (set by admin)
    mapping(uint256 => uint256) public planWeeklyReward;

    // nodeId => NodeInfo
    mapping(string => NodeInfo) public nodes;

    // user => nodeIds[]
    mapping(address => string[]) public userNodes;

    // tracking rewards
    mapping(address => uint256) public totalClaimedRewards; 
    mapping(address => mapping(string => uint256)) public nodeClaimedRewards;

    // events
    event RewardClaimed(address indexed user, string nodeId, uint256 amount);
    event NodeRegistered(address indexed user, string nodeId, uint256 planId);
    event NodeDeactivated(string nodeId);

    constructor(address _rewardToken) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
    }

    // ✅ Admin sets plan reward
    function setPlanReward(uint256 planId, uint256 weeklyReward) external onlyOwner {
        planWeeklyReward[planId] = weeklyReward;
    }

    // ✅ Store user node purchase
    function registerNode(
        string memory nodeId,
        address user,
        uint256 planId,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(bytes(nodes[nodeId].nodeId).length == 0, "Node already exists");
        require(endTime > startTime, "Invalid duration");
        require(planWeeklyReward[planId] > 0, "Plan not configured");

        nodes[nodeId] = NodeInfo({
            nodeId: nodeId,
            user: user,
            planId: planId,
            startTime: startTime,
            endTime: endTime,
            lastClaimed: startTime,
            active: true
        });

        // FIX ✅ (store under correct user)
        userNodes[user].push(nodeId);

        emit NodeRegistered(user, nodeId, planId);
    }

    // ✅ View pending rewards (before claiming)
    function pendingReward(string memory nodeId) public view returns (uint256) {
        NodeInfo memory node = nodes[nodeId];
        if (!node.active || block.timestamp <= node.lastClaimed) return 0;

        uint256 claimUntil = block.timestamp < node.endTime
            ? block.timestamp
            : node.endTime;

        if (claimUntil <= node.lastClaimed) return 0;

        uint256 weeksPassed = (claimUntil - node.lastClaimed) / 10 minutes;
        return weeksPassed * planWeeklyReward[node.planId];
    }

    // ✅ Claim rewards
    function claimReward(string memory nodeId) external {
        NodeInfo storage node = nodes[nodeId];
        require(node.active, "Node not active");
        require(msg.sender == node.user, "Not node owner");

        uint256 rewardAmount = pendingReward(nodeId);
        require(rewardAmount > 0, "No rewards available");
        uint256 claimUntil = block.timestamp < node.endTime
            ? block.timestamp
            : node.endTime;

        uint256 weeksPassed = (claimUntil - node.lastClaimed) / 10 minutes;
        node.lastClaimed += weeksPassed * 10 minutes;

        if (block.timestamp >= node.endTime) {
            node.active = false;
            emit NodeDeactivated(nodeId);
        }

        require(
            rewardToken.balanceOf(address(this)) >= rewardAmount,
            "Insufficient rewards in contract"
        );

        rewardToken.safeTransfer(node.user, rewardAmount);

        nodeClaimedRewards[node.user][nodeId] += rewardAmount;
        totalClaimedRewards[node.user] += rewardAmount;

        emit RewardClaimed(node.user, nodeId, rewardAmount);
    }

    // ✅ Optional - deactivate node after expiry (manual)
    function deactivateNode(string memory nodeId) external onlyOwner {
        nodes[nodeId].active = false;
        emit NodeDeactivated(nodeId);
    }

    function getTotalClaimed(address user) external view returns (uint256) {
        return totalClaimedRewards[user];
    }

    function getNodeClaimed(
        address user,
        string memory nodeId
    ) external view returns (uint256) {
        return nodeClaimedRewards[user][nodeId];
    }

    function getUserNodes(
        address user
    ) external view returns (string[] memory) {
        return userNodes[user];
    }


   function tokenBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
}

