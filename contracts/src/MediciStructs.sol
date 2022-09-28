pragma solidity 0.8.15;

library MediciStructs {
    struct Loan {
        address borrower;
        uint256 principal;
        uint256 tenor;
        uint256 repaymentTime;
        address collateral;
        uint256 collateralAmt;
    }

    function encodeLoan(Loan memory _loan) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(1),
            _loan.borrower,
            _loan.principal,
            _loan.tenor,
            _loan.repaymentTime,
            _loan.collateral,
            _loan.collateralAmt
        );
    }
}
