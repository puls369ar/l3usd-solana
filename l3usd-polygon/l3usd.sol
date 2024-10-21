contract L3USD is Pausable, StandardToken, BlackList {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    bool public deprecated;
    mapping(address => bool) public minters;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    constructor() {
        _totalSupply = 0;
        name = "L3USD";
        symbol = "L3USD";
        decimals = 18;
        deprecated = false;
        minters[owner] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender]);
        _;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) override public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) override public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) override public view returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint _value) override public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) override public view returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() override public view returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyMinter {
        require(_totalSupply + amount > _totalSupply);
        require(balances[msg.sender] + amount > balances[msg.sender]);

        balances[msg.sender] += amount;
        _totalSupply += amount;
        emit Issue(msg.sender, amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function addMinter(address newMinter) public onlyOwner {
        require(newMinter != address(0));
        require(!minters[newMinter]);
        minters[newMinter] = true;
        emit AddMinter(newMinter);
    }

    function removeMinter(address minterToRemove) public onlyOwner {
        require(minters[minterToRemove]);
        minters[minterToRemove] = false;
        emit RemoveMinter(minterToRemove);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    // Called when new token are issued
    event Issue(address minter, uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);

    // Called when minter is added
    event AddMinter(address newMinter);

    // Called when minter is removed
    event RemoveMinter(address removedMinter);
}
