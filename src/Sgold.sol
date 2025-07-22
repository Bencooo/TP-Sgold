// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Sgold is ERC20, Ownable {
    address public minter;

    error NotAuthorized();

    constructor(address initialOwner) ERC20("Sgold", "SGOLD") Ownable(initialOwner) {}

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert NotAuthorized();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != minter) revert NotAuthorized();
        _burn(from, amount);
    }
}
