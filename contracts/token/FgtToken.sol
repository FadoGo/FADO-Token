// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

interface IBPContract {

    function protect(address sender, address receiver, uint256 amount) external;

}

contract FgtToken is AccessControlEnumerable, ERC20Burnable, ERC20Pausable, ERC20Capped {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IBPContract public bpContract;

    bool public bpEnabled;
    bool public bpDisabledForever;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FgtToken: must have admin role to call");
        _;
    }

    constructor(string memory name, string memory symbol, uint256 maxSupply)
        ERC20(name, symbol)
        ERC20Capped(maxSupply)
    {
        address msgSender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);

        _setupRole(MINTER_ROLE, msgSender);
        _setupRole(PAUSER_ROLE, msgSender);
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "FgtToken: must have minter role to mint");

        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "FgtToken: must have pauser role to pause");

        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "FgtToken: must have pauser role to unpause");

        _unpause();
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);

        if (bpEnabled && !bpDisabledForever) {
            bpContract.protect(from, to, amount);
        }
    }

    function setBPContract(address addr) public onlyAdmin {
        require(address(bpContract) == address(0), "FgtToken: can only be initialized once");

        bpContract = IBPContract(addr);
    }

    function setBPEnabled(bool enabled) public onlyAdmin {
        bpEnabled = enabled;
    }

    function setBPDisableForever() public onlyAdmin {
        require(!bpDisabledForever, "FgtToken: bot prevention disabled");

        bpDisabledForever = true;
    }

}