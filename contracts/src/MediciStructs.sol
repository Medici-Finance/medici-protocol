pragma solidity 0.8.15;

import "./helpers/BytesLib.sol";
import "forge-std/console.sol";

struct Loan {
    bytes borrower;
    uint256 worldID;
    uint256 principal;
    uint256 pending;
    uint256 tenor;
    uint256 apr; // 100% - 18 decimals
    uint256 repaymentTime;
    address collateral;
    uint256 collateralAmt;
}

struct MessageHeader {
    uint8 payloadID;
    // address of the sender
    address sender;
    // collateral info
    address collateralAddress; // for verification
    // borrow info
    address borrowAddress; // for verification
}

struct BorrowRequestMessage {
    // payloadID = 1
    MessageHeader header;
    uint256 borrowAmount;
    uint256 totalNormalizedBorrowAmount;
    uint256 tenor;
    uint256 apr;
}

struct BorrowApproveMessage {
    // payloadID = 2
    MessageHeader header;
    uint256 loanId;
    uint256 approveAmount;
    uint256 totalNormalizedApproveAmount;
}

struct BorrowReceiptMessage {
    // payloadID = 3
    MessageHeader header;
    uint16 chainId;
    uint256 loanId;
    address recipient;
    uint256 amount;
}

struct CreditLine {
    bytes lender;
    uint256 amount;
}

struct RiskProfile {
    CreditLine[] lenders;
    uint256[] loans;
    uint256 creditLine;
}

contract MediciStructs {
    using BytesLib for bytes;

    function encodeMessageHeader(MessageHeader memory header) internal pure returns (bytes memory) {
        return abi.encodePacked(header.sender, header.collateralAddress, header.borrowAddress);
    }

    function decodeMessageHeader(bytes memory serialized) internal pure returns (MessageHeader memory header) {
        uint256 index = 0;

        // parse the header
        header.payloadID = serialized.toUint8(index += 1);
        header.sender = serialized.toAddress(index += 20);
        header.collateralAddress = serialized.toAddress(index += 20);
        header.borrowAddress = serialized.toAddress(index += 20);
    }

    function encodeBorrowRequestMessage(BorrowRequestMessage memory message) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(1), // payloadID
            encodeMessageHeader(message.header),
            message.borrowAmount,
            message.totalNormalizedBorrowAmount,
            message.tenor,
            message.apr
        );
    }

    function decodeBorrowRequestMessage(bytes memory serialized)
        internal
        pure
        returns (BorrowRequestMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(serialized.slice(index, index += 61));
        params.borrowAmount = serialized.toUint256(index += 32);
        params.totalNormalizedBorrowAmount = serialized.toUint256(index += 32);
        params.tenor = serialized.toUint256(index += 32);
        params.apr = serialized.toUint256(index += 32);

        require(params.header.payloadID == 1, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function encodeBorrowApproveMessage(BorrowApproveMessage memory message) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(2), // payloadID
            encodeMessageHeader(message.header),
            message.loanId,
            message.approveAmount,
            message.totalNormalizedApproveAmount
        );
    }

    function decodeBorrowApproveMessage(bytes memory serialized)
        internal
        pure
        returns (BorrowApproveMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(serialized.slice(index, index += 61));
        params.loanId = serialized.toUint256(index += 32);
        params.approveAmount = serialized.toUint256(index += 32);
        params.totalNormalizedApproveAmount = serialized.toUint256(index += 32);

        require(params.header.payloadID == 2, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function encodeBorrowReceiptMessage(BorrowReceiptMessage memory message) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(3), // payloadID
            encodeMessageHeader(message.header),
            message.chainId,
            message.loanId,
            message.recipient,
            message.amount
        );
    }

    function decodeBorrowReceiptMessage(bytes memory serialized)
        internal
        pure
        returns (BorrowReceiptMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(serialized.slice(index, index += 61));
        params.chainId = serialized.toUint16(index += 16);
        params.loanId = serialized.toUint256(index += 32);
        params.recipient = serialized.toAddress(index += 20);
        params.amount = serialized.toUint256(index += 32);

        require(params.header.payloadID == 3, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function encodeWAddress(uint16 _chainId, address _address) public returns (bytes memory) {
        bytes memory addy = new bytes(32);
        assembly {
            mstore(add(addy, 32), _address)
        }
        return bytes.concat(toBytes(_chainId), addy);
    }

    function decodeWAddress(bytes memory _address) public returns (uint16, address) {
        // uint16 chainID = uint16(_address[0]);
        // address addy;
        // assembly {
        //     addy := mload(add(_address, 32))
        // }
        return (0, address(0));
    }

    function toBytes(uint16 x) public returns (bytes memory c) {
        bytes2 b = bytes2(x);
        c = new bytes(2);
        for (uint256 i = 0; i < 2; i++) {
            c[i] = b[i];
        }
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
