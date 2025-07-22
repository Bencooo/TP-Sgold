// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Sgold.sol";

contract SgoldTest is Test {
    Sgold sgold;
    address owner = address(0xABCD);
    address minter = address(0xBEEF);
    address user = address(0xCAFE);

    function setUp() public {
        vm.prank(owner);
        sgold = new Sgold(owner);
    }

    function testInitialOwner() public {
        assertEq(sgold.owner(), owner);
    }

    function testSetMinter() public {
        vm.prank(owner);
        sgold.setMinter(minter);
        assertEq(sgold.minter(), minter);
    }

    function testMintAuthorized() public {
        vm.prank(owner);
        sgold.setMinter(minter);

        vm.prank(minter);
        sgold.mint(user, 1000);

        assertEq(sgold.balanceOf(user), 1000);
    }

    function testMintUnauthorizedReverts() public {
        vm.expectRevert(Sgold.NotAuthorized.selector);
        sgold.mint(user, 1000);
    }

    function testBurnAuthorized() public {
        vm.prank(owner);
        sgold.setMinter(minter);

        vm.prank(minter);
        sgold.mint(user, 1000);

        vm.prank(minter);
        sgold.burn(user, 400);

        assertEq(sgold.balanceOf(user), 600);
    }

    function testBurnUnauthorizedReverts() public {
        vm.prank(owner);
        sgold.setMinter(minter);

        vm.prank(minter);
        sgold.mint(user, 1000);

        vm.expectRevert(Sgold.NotAuthorized.selector);
        sgold.burn(user, 500);
    }
}

