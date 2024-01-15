// SPDX-License-Identifier: MIT

import 'lib/ERC721A/contracts/ERC721A.sol';

contract ERC721ATest is ERC721A {

    constructor() ERC721A("TKN", "TKN") { }

    function isBurned(uint tokenId) public view returns (bool) {
        return _packedOwnershipOf(tokenId) & _BITMASK_BURNED != 0;
    }

    //
    // mint
    //

    function mint(address to, uint quantity) public {
        _mint(to, quantity);
    }

    function proveMintRequirements(address to, uint quantity) public {
        _mint(to, quantity);

        assert(to != address(0));
        assert(quantity > 0);
    }

    function proveMintNextTokenIdUpdate(address to, uint quantity) public {
        uint oldNextTokenId = _nextTokenId();
        require(oldNextTokenId <= type(uint96).max); // practical assumption needed for overflow/underflow not occurring

        mint(to, quantity);

        uint newNextTokenId = _nextTokenId();

        assert(newNextTokenId >= oldNextTokenId); // ensuring no overflow
        assert(newNextTokenId == oldNextTokenId + quantity);
    }

    function proveMintBalanceUpdate(address to, uint quantity, uint tokenId) public {
        uint oldBalanceTo = balanceOf(to);
        require(oldBalanceTo <= type(uint64).max / 2); // practical assumption needed for balance staying within uint64

        mint(to, quantity);

        uint newBalanceTo = balanceOf(to);

        assert(newBalanceTo > oldBalanceTo); // ensuring no overflow
        assert(newBalanceTo == oldBalanceTo + quantity);
    }

    function proveMintOwnershipUpdate(address to, uint quantity, uint _newNextTokenId) public {
        uint oldNextTokenId = _nextTokenId();
        require(oldNextTokenId <= type(uint96).max); // practical assumption needed for overflow/underflow not occurring

        // global invariant
        for (uint i = oldNextTokenId; i < _newNextTokenId; i++) {
            require(_packedOwnerships[i] == 0); // assumption for uninitialized mappings (i.e., no hash collision for hashed storage addresses)
        }

        mint(to, quantity);

        uint newNextTokenId = _nextTokenId();
        require(_newNextTokenId == newNextTokenId);

        for (uint i = oldNextTokenId; i < newNextTokenId; i++) {
            assert(ownerOf(i) == to);
            assert(!isBurned(i));
        }
    }

    function proveMintOtherBalancePreservation(address to, uint quantity, address others) public {
        require(others != to); // consider other addresses

        uint oldBalanceOther = balanceOf(others);

        mint(to, quantity);

        uint newBalanceOther = balanceOf(others);

        assert(newBalanceOther == oldBalanceOther); // the balance of other addresses never change
    }

    function proveMintOtherOwnershipPreservation(address to, uint quantity, uint existingTokenId) public {
        uint oldNextTokenId = _nextTokenId();
        require(oldNextTokenId <= type(uint96).max); // practical assumption needed for overflow/underflow not occurring

        require(existingTokenId < oldNextTokenId); // consider other token ids

        address oldOwnerExisting = ownerOf(existingTokenId);
        bool oldBurned = isBurned(existingTokenId);

        mint(to, quantity);

        address newOwnerExisting = ownerOf(existingTokenId);
        bool newBurned = isBurned(existingTokenId);

        assert(newOwnerExisting == oldOwnerExisting); // the owner of other token ids never change
        assert(newBurned == oldBurned);
    }

    //
    // burn
    //

    // TODO: duplicate spec for both modes
    function burn(uint tokenId) public {
      //_burn(tokenId, true);
        _burn(tokenId, false);
    }

    function proveBurnRequirements(uint tokenId) public {
        // TODO: prove global invariant
        require(!(_packedOwnerships[tokenId] == 0) || !isBurned(tokenId));
        require(!(_packedOwnerships[tokenId] != 0) || tokenId < _nextTokenId());

        bool exist = _exists(tokenId);
        bool burned = isBurned(tokenId);

        address owner = ownerOf(tokenId);
        bool approved = msg.sender == _tokenApprovals[tokenId].value || isApprovedForAll(owner, msg.sender);

        _burn(tokenId, true);

        assert(exist); // it should have reverted if the token id does not exist
        assert(!burned);

        assert(msg.sender == owner || approved);

        assert(_tokenApprovals[tokenId].value == address(0)); // getApproved(tokenId) reverts here
    }

    function proveBurnNextTokenIdUnchanged(uint tokenId) public {
        uint oldNextTokenId = _nextTokenId();

        burn(tokenId);

        uint newNextTokenId = _nextTokenId();

        assert(newNextTokenId == oldNextTokenId);
    }

    function proveBurnBalanceUpdate(uint tokenId) public {
        address from = ownerOf(tokenId);
        uint oldBalanceFrom = balanceOf(from);

        // TODO: prove global invariant
        require(!(_packedOwnerships[tokenId] != 0) || tokenId < _nextTokenId());
        require(!_exists(tokenId) || oldBalanceFrom > 0);

        burn(tokenId);

        uint newBalanceFrom = balanceOf(from);

        assert(newBalanceFrom < oldBalanceFrom); // ensuring no overflow
        assert(newBalanceFrom == oldBalanceFrom - 1);
    }

    function proveBurnOwnershipUpdate(uint tokenId) public {
        burn(tokenId);

        assert(!_exists(tokenId));
        assert(_packedOwnerships[tokenId] & _BITMASK_BURNED != 0); // isBurned reverts here
    }

    function proveBurnOtherBalancePreservation(uint tokenId, address others) public {
        address from = ownerOf(tokenId);
        require(others != from); // consider other addresses

        uint oldBalanceOther = balanceOf(others);

        burn(tokenId);

        uint newBalanceOther = balanceOf(others);

        assert(newBalanceOther == oldBalanceOther);
    }

    function proveBurnOtherOwnershipPreservation(uint tokenId, uint otherTokenId) public {
        require(_nextTokenId() <= type(uint96).max); // practical assumption needed for avoiding overflow/underflow

        // TODO: prove global invariant
        // global invariant
        require(!(_packedOwnerships[tokenId] == 0) || _packedOwnershipOf(tokenId) & _BITMASK_NEXT_INITIALIZED == 0);
        require(!(_packedOwnerships[tokenId] != 0) || tokenId < _nextTokenId());
        require(!(_packedOwnershipOf(tokenId) & _BITMASK_NEXT_INITIALIZED != 0)
             || !(tokenId + 1 < _nextTokenId())
             || _packedOwnerships[tokenId + 1] != 0);

        require(otherTokenId != tokenId); // consider other token ids

        address oldOtherTokenOwner = ownerOf(otherTokenId);
        bool oldBurned = isBurned(otherTokenId);

        burn(tokenId);

        address newOtherTokenOwner = ownerOf(otherTokenId);
        bool newBurned = isBurned(otherTokenId);

        assert(newOtherTokenOwner == oldOtherTokenOwner);
        assert(newBurned == oldBurned);
    }

    //
    // transfer
    //

    // TODO: duplicate spec for safeTransferFrom
    function transfer(address from, address to, uint tokenId) public {
        transferFrom(from, to, tokenId);
      //safeTransferFrom(from, to, tokenId);
      //safeTransferFrom(from, to, tokenId, data);
    }

    function proveTransferRequirements(address from, address to, uint tokenId) public {
        // TODO: prove global invariant
        require(!(_packedOwnerships[tokenId] == 0) || !isBurned(tokenId));
        require(!(_packedOwnerships[tokenId] != 0) || tokenId < _nextTokenId());

        bool exist = _exists(tokenId);
        bool burned = isBurned(tokenId);

        address owner = ownerOf(tokenId);
        bool approved = msg.sender == _tokenApprovals[tokenId].value || isApprovedForAll(owner, msg.sender);

        transfer(from, to, tokenId);

        assert(exist); // it should have reverted if the token id does not exist
        assert(!burned);

      //assert(from != address(0)); // NOTE: ERC721A doesn't explicitly check this condition
        assert(to != address(0));

        assert(from == owner);
        assert(msg.sender == owner || approved);

        assert(_tokenApprovals[tokenId].value == address(0));
    }

    function proveTransferNextTokenIdUnchanged(address from, address to, uint tokenId) public {
        uint oldNextTokenId = _nextTokenId();

        transfer(from, to, tokenId);

        uint newNextTokenId = _nextTokenId();

        assert(newNextTokenId == oldNextTokenId);
    }

    function proveTransferBalanceUpdate(address from, address to, uint tokenId) public {
        require(from != to); // consider normal transfer case (see below for the self-transfer case)

        uint oldBalanceFrom = balanceOf(from);
        uint oldBalanceTo   = balanceOf(to);

        require(oldBalanceTo <= type(uint64).max / 2); // practical assumption needed for balance staying within uint64

        // TODO: prove global invariant
        require(!(_packedOwnerships[tokenId] != 0) || tokenId < _nextTokenId());
        require(!_exists(tokenId) || balanceOf(ownerOf(tokenId)) > 0);

        transfer(from, to, tokenId);

        uint newBalanceFrom = balanceOf(from);
        uint newBalanceTo   = balanceOf(to);

        assert(newBalanceFrom < oldBalanceFrom);
        assert(newBalanceFrom == oldBalanceFrom - 1);

        assert(newBalanceTo > oldBalanceTo);
        assert(newBalanceTo == oldBalanceTo + 1);
    }

    function proveTransferBalanceUnchanged(address from, address to, uint tokenId) public {
        require(from == to); // consider self-transfer case
        mint(from, 1);

        uint oldBalance = balanceOf(from); // == balanceOf(to);

        transfer(from, to, tokenId);

        uint newBalance = balanceOf(from); // == balanceOf(to);

        assert(newBalance == oldBalance);
    }

    function proveTransferOwnershipUpdate(address from, address to, uint tokenId) public {
        transfer(from, to, tokenId);

        assert(ownerOf(tokenId) == to);
        assert(!isBurned(tokenId));
    }

    function proveTransferOtherBalancePreservation(address from, address to, uint tokenId, address others) public {
        require(others != from); // consider other addresses
        require(others != to);

        uint oldBalanceOther = balanceOf(others);

        transfer(from, to, tokenId);

        uint newBalanceOther = balanceOf(others);

        assert(newBalanceOther == oldBalanceOther);
    }

    function proveTransferOtherOwnershipPreservation(address from, address to, uint tokenId, uint otherTokenId) public {
        require(_nextTokenId() <= type(uint96).max); // practical assumption needed for avoiding overflow/underflow

        // TODO: prove global invariant
        // global invariant
        require(!(_packedOwnerships[tokenId] == 0) || _packedOwnershipOf(tokenId) & _BITMASK_NEXT_INITIALIZED == 0);
        require(!(_packedOwnerships[tokenId] != 0) || tokenId < _nextTokenId());
        require(!(_packedOwnershipOf(tokenId) & _BITMASK_NEXT_INITIALIZED != 0)
             || !(tokenId + 1 < _nextTokenId())
             || _packedOwnerships[tokenId + 1] != 0);

        require(otherTokenId != tokenId); // consider other token ids

        address oldOtherTokenOwner = ownerOf(otherTokenId);
        bool oldBurned = isBurned(otherTokenId);

        transfer(from, to, tokenId);

        address newOtherTokenOwner = ownerOf(otherTokenId);
        bool newBurned = isBurned(otherTokenId);

        assert(newOtherTokenOwner == oldOtherTokenOwner);
        assert(newBurned == oldBurned);
    }
}
