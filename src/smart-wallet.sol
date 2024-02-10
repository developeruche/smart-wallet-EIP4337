import {BaseAccount} from "@account-abstraction/contracts/core/BaseAccount.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";





// @title SmartAccount
// @notice This a smart contract wallet following the specs of EIP4337, with social recovery
contract SmartAccount is BaseAccount {
    using ECDSA for bytes32;



    // ==================================
    // STATE VARIABLES
    // ==================================
    IEntryPoint private immutable _entryPoint;
    address private _owner;
    uint256 private _socialRecoverCount;
    address private _newOwner;
    mapping(address => bool) private _isSocialRecoveryOperator;



    constructor(IEntryPoint __entryPoint, address[] memory socialRecoveryOperators) {
        _entryPoint = __entryPoint;
        require(socialRecoveryOperators.length >= 5, "not enough social recovery operators");
        for (uint256 i = 0; i < socialRecoveryOperators.length; i++) {
            _isSocialRecoveryOperator[socialRecoveryOperators[i]] = true;
        }
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        address signer = ECDSA.recover(userOpHash.toEthSignedMessageHash(), userOp.signature);

        if (signer != _owner) {
            return SIG_VALIDATION_FAILED;
        }

        return 0;
    }


    function performSocialRecovery(address newOwner) public {
        require(_isSocialRecoveryOperator[msg.sender], "not a social recovery operator");
        _newOwner = newOwner;
        _socialRecoverCount++;

        if (_socialRecoverCount >= 5) {
            _owner = _newOwner;
            _newOwner = address(0);
            _socialRecoverCount = 0;
        }
    }
}