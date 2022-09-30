pragma solidity 0.8.15;

import "./helpers/BytesLib.sol";

library MediciStructs {
    using BytesLib for bytes;
    struct Loan {
        address borrower;
        uint256 principal;
        uint256 tenor;
        uint256 repaymentTime;
        address collateral;
        uint256 collateralAmt;
    }

    struct RiskProfile {
        uint256[] trustors;
        Loan[] loans;
        uint256 creditLine;
    }

    function encodeLoan(Loan memory _loan) public pure returns (bytes memory) {
        return abi.encodePacked(
            _loan.borrower,
            _loan.principal,
            _loan.tenor,
            _loan.repaymentTime,
            _loan.collateral,
            _loan.collateralAmt
        );
    }

    function parseLoan(bytes memory encoded) public pure returns (Loan memory loan) {
        uint256 index = 0;

        loan.borrower = encoded.toAddress(index);
        index += 20;

        loan.principal = encoded.toUint256(index);
        index += 32;

        loan.tenor = encoded.toUint256(index);
        index += 32;

        loan.repaymentTime = encoded.toUint256(index);
        index += 32;

        loan.collateral = encoded.toAddress(index);
        index += 20;

        loan.collateralAmt = encoded.toUint256(index);
        index += 32;
    }

    /**
     * @dev verify and check if the emitter sender is worldId holder
     * TODO later: verify the signature
     */
    // function verifySignature(bytes memory encodedHashData, bytes memory sig, address authority) public pure returns (bool) {
    //     require(sig.length == 65, "incorrect signature length");
    //     require(encodedHashData.length > 0, "no hash data");

    //     /// compute hash from encoded data
    //     bytes32 hash_ = keccak256(encodedHashData);

    //     /// parse v, r, s
    //     uint8 index = 0;

    //     bytes32 r = sig.toBytes32(index);
    //     index += 32;

    //     bytes32 s = sig.toBytes32(index);
    //     index += 32;

    //     uint8 v = sig.toUint8(index) + 27;

    //     /// recovered key
    //     address key = ecrecover(hash_, v, r, s);

    //     /// confirm that the recovered key is the authority
    //     if (key == authority) {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }
}
