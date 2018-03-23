pragma solidity ^0.4.18;

contract ERC20 {
    function totalSupply() public constant returns (uint _totalSupply);

    function balanceOf(address _owner) public constant returns (uint balance);

    function transfer(address _to, uint _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    function approve(address _spender, uint _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract CrowdSale {
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
    uint256 public price;
    ERC20 public tokenReward;
    address public tokenFrom;

    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdSaleClosed = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    function CrowdSale(
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        uint256 durationInMinutes,
        uint256 weiCostOfEachToken,
        address addressOfTokenUsedAsReward,
        address addressOfTokenFrom
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken * 1 wei;
        tokenReward = ERC20(addressOfTokenUsedAsReward);
        tokenFrom = addressOfTokenFrom;
    }

    function() payable public {
        require(!crowdSaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transferFrom(tokenFrom, msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }

    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdSaleClosed = true;
    }

    function safeWithdraw() afterDeadline public {
        if (!fundingGoalReached) {
            uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
}

