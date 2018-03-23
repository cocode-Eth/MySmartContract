pragma solidity ^0.4.18;

// https://github.com/ethereum/EIPs/issues/20

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

library SafeMath {

    function mul(uint256 x, uint256 y) internal pure returns (uint256)  {
        if (x == 0) {
            return 0;
        }
        uint256 z = x * y;
        assert(z / x == y);
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256)  {
        uint256 z = x / y;
        return z;
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256)  {
        uint256 z = x + y;
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256)  {
        assert(y <= x);
        return x - y;
    }
}

contract OurToken is ERC20 {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public maxSupplyToken;
    mapping(address => bool) public frozen;

    uint256 private totalSupplyToken;
    address private tokenOwner;
    mapping(address => uint256) private balanceToken;
    mapping(address => mapping(address => uint256)) private allowanceToken;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event OwnerChange(address indexed _from, address indexed _to);
    event Mint(address indexed _owner, uint _value);
    event Burn(address indexed _owner, uint _value);
    event PermissionChange(address indexed _owner, bool _frozen);

    function OurToken(string tokenName, string tokenSymbol, uint256 _maxSupplyToken, uint256 initSupplyToken, uint256 _decimals) public {
        require(bytes(tokenName).length > 0);
        require(bytes(tokenSymbol).length > 0);
        require(initSupplyToken != 0x00);
        require(_maxSupplyToken != 0x00);
        require (_decimals != 0x00);
        require(_maxSupplyToken >= initSupplyToken);

        name = tokenName;
        symbol = tokenSymbol;
        maxSupplyToken = _maxSupplyToken;
        totalSupplyToken = initSupplyToken;
        tokenOwner = msg.sender;
        balanceToken[tokenOwner] = totalSupplyToken;
        decimals = _decimals;
        Transfer(0, tokenOwner, totalSupplyToken);
        OwnerChange(0, tokenOwner);
    }

    function() payable public {
        require(false);
    }

    function ownerChange(address _to) public returns (bool success) {
        require(msg.sender != 0x00);
        require(msg.sender == tokenOwner);
        require(_to != 0x00);
        tokenOwner = _to;
        OwnerChange(msg.sender, _to);
        assert(msg.sender != tokenOwner);
        return true;
    }

    function mint(uint256 _value) public returns (bool success) {
        require(msg.sender != 0x00);
        require(msg.sender == tokenOwner);
        require(_value != 0x00);
        require(maxSupplyToken >= totalSupplyToken.add(_value));
        uint256 preTotalSupplyToken = totalSupplyToken;
        totalSupplyToken = totalSupplyToken.add(_value);
        balanceToken[tokenOwner] = balanceToken[tokenOwner].add(_value);
        Mint(msg.sender, _value);
        Transfer(0, msg.sender, _value);
        assert(totalSupplyToken == preTotalSupplyToken.add(_value));
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender != 0x00);
        require(_value != 0x00);
        require(balanceToken[msg.sender] > _value);
        balanceToken[msg.sender] = balanceToken[msg.sender].sub(_value);
        totalSupplyToken = totalSupplyToken.sub(_value);
        Transfer(msg.sender, 0, _value);
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _owner, uint256 _value) public returns (bool success) {
        require(_owner != 0x00);
        require(_value != 0x00);
        require(balanceToken[_owner] > _value);
        require(allowanceToken[_owner][msg.sender] > _value);
        allowanceToken[_owner][msg.sender] = allowanceToken[_owner][msg.sender].sub(_value);
        balanceToken[_owner] = balanceToken[_owner].sub(_value);
        totalSupplyToken = totalSupplyToken.sub(_value);
        Approval(_owner, msg.sender, allowanceToken[_owner][msg.sender]);
        Transfer(_owner, 0, _value);
        Burn(_owner, _value);
        return true;
    }

    function freeze(address _account) public returns (bool success){
        require(msg.sender != 0x00);
        require(msg.sender == tokenOwner);
        require(_account != 0x00);
        require (_account != tokenOwner);
        require(!frozen[_account]);
        frozen[_account] = true;
        PermissionChange(_account, true);
        return true;
    }

    function unfreeze(address _account) public returns (bool success){
        require(msg.sender != 0x00);
        require(msg.sender == tokenOwner);
        require(_account != 0x00);
        require (_account != tokenOwner);
        require(frozen[_account]);
        frozen[_account] = false;
        PermissionChange(_account, false);
        return true;
    }    

    function totalSupply() public constant returns (uint _totalSupply) {
        return totalSupplyToken;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balanceToken[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(msg.sender != 0x00);
        require(_to != 0x00);
        require(_value != 0x00);
        require(balanceToken[msg.sender] >= _value);
        require(balanceToken[_to].add(_value) > balanceToken[_to]);
        require(!frozen[msg.sender]);

        frozen[msg.sender] = true;
        uint256 preCount = balanceToken[msg.sender].add(balanceToken[_to]);

        balanceToken[msg.sender] = balanceToken[msg.sender].sub(_value);
        balanceToken[_to] = balanceToken[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        frozen[msg.sender] = false;
        assert(balanceToken[msg.sender].add(balanceToken[_to]) == preCount && !frozen[msg.sender]);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_from != 0x00);
        require(_to != 0x00);
        require(_value != 0x00);
        require(balanceToken[_from] >= _value);
        require(allowanceToken[_from][msg.sender] >= _value);
        require(balanceToken[_to].add(_value) > balanceToken[_to]);
        require(!frozen[_from]);
        frozen[_from] = true;
        uint256 preCount = balanceToken[_from].add(balanceToken[_to]);

        allowanceToken[_from][msg.sender] = allowanceToken[_from][msg.sender].sub(_value);
        balanceToken[_from] = balanceToken[_from].sub(_value);
        balanceToken[_to] = balanceToken[_to].add(_value);

        Transfer(_from, _to, _value);
        frozen[_from] = false;
        assert(balanceToken[_from].add(balanceToken[_to]) == preCount && !frozen[_from]);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        require(msg.sender != 0x00);
        require(_spender != 0x00);
        require(msg.sender != _spender);
        require(_value != 0x00);
        require(balanceToken[msg.sender] >= _value);

        allowanceToken[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowanceToken[_owner][_spender];
    }

}
