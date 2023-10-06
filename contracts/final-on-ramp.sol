// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OnRampData is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct UserOnRampData {
        address walletAddress;
        string paymentType;
        uint256 initiateTs;
        string onMetaTransactionID;
        string userId;
        Status status;
        string passType;
        uint256 passAmount;
    }

    enum Status {
        fiatPending, //0
        orderReceived, //1
        Transferred, //2
        Completed //3
    }
    uint256 private totalTransactionCount;

    mapping(string => UserOnRampData) public useronrampdata;
    mapping(address => string[]) private userTransactions;
    mapping(string => UserOnRampData) public onRampOrderId;

    uint256 private countFiatPending;
    uint256 private countOrderReceived;
    uint256 private countTransferred;
    uint256 private countCompleted;
    uint256 private countFiatPayments;
    uint256 private countCryptoPayments;
    uint256 public totalFiatSpent;
    uint256 public totalCryptoSpent;
    uint256 private countStandardPass;
    uint256 private countPremimumPass;

    constructor() {
        totalTransactionCount = 0;
    }

    event UpgradePassTypeInitiation(
        string indexed userId,
        address walletAddress,
        string passType,
        uint256 timestamp,
        uint256 passAmount
    );
    event UpdatePurchasePassCreated(
        string indexed userId,
        address walletAddress,
        string paymentType,
        uint256 fiatTimeStamp
    );
    event UpdatePassTransactionStatus(
        string indexed userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string onMetaTransactionID,
        uint256 initiateTs
    );
    event CustomMessageSent(
        string indexed userId,
        string message,
        uint256 initiateTs,
        address walletAddress
    );

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function upgradePassType(
        string memory userId,
        address walletAddress,
        string memory passType,
        uint256 passAmount
    ) external nonReentrant onlyOwner {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(bytes(passType).length > 0, "Invalid passType ");
        if (compareStrings(passType, "Standard")) {
            countStandardPass++;
        } else if (compareStrings(passType, "Premimum")) {
            countPremimumPass++;
        }

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        data.passType = passType;
        data.passAmount = passAmount;
        uint256 initiateTs = block.timestamp;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit UpgradePassTypeInitiation(
            userId,
            walletAddress,
            passType,
            initiateTs,
            passAmount
        );
    }

    function purchasePassCreated(
        string memory userId,
        address walletAddress,
        string memory paymentType,
        string memory passType,
        uint256 passAmount
    ) external nonReentrant onlyOwner {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(bytes(passType).length > 0, "Invalid passType ");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(bytes(paymentType).length > 0, "Invalid payment mode");
        if (compareStrings(paymentType, "Fiat")) {
            countFiatPayments++;
            incrementTotalTransactionCount(); //increaments the count when function is triggered
        } else if (compareStrings(paymentType, "Crypto")) {
            countCryptoPayments++;
            totalCryptoSpent += totalCryptoPassAmount(passAmount);
            incrementTotalTransactionCount(); //increaments the count when function is triggered
        } else {
            revert("inavlid payment type");
        }

        UserOnRampData storage data = useronrampdata[userId];

        data.walletAddress = walletAddress;
        data.paymentType = paymentType;
        data.passType = passType;
        data.passAmount = passAmount;
        uint256 fiatTimeStamp = block.timestamp;
        userTransactions[walletAddress].push(userId);

        emit UpdatePurchasePassCreated(
            userId,
            walletAddress,
            paymentType,
            fiatTimeStamp
        );
    }

    function updatePassStatus(
        string memory userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string memory onMetaTransactionID,
        string memory orderId
    ) external nonReentrant onlyOwner returns (Status) {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(
            bytes(onMetaTransactionID).length > 0,
            "onMetaTransactionID cannot be empty"
        );

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        uint256 initiateTs = block.timestamp;

        // Depending on the 'status' input, update the appropriate count
        if (status == Status.fiatPending) {
            countFiatPending++;
            onRampOrderId[orderId] = data;

            incrementTotalTransactionCount();
        } else if (status == Status.orderReceived) {
            countOrderReceived++;
            incrementTotalTransactionCount();
        } else if (status == Status.Transferred) {
            countTransferred++;
            countFiatPayments++;
            incrementTotalTransactionCount();
        } else if (status == Status.Completed) {
            countCompleted++;
            totalFiatSpent += totalFiatPassAmount(passAmount);
            incrementTotalTransactionCount();
        } else {
            revert("invalid status");
        }
        data.status = status;
        userTransactions[walletAddress].push(userId);

        emit UpdatePassTransactionStatus(
            userId,
            walletAddress,
            passAmount,
            status,
            onMetaTransactionID,
            initiateTs
        ); //Emits the data specified in the parameters.
    }

    function onCanceled(
        string memory userId,
        string memory message,
        address walletAddress
    ) external {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(bytes(message).length > 0, "Message cannot be empty");
        require(walletAddress != address(0), "Invalid wallet address");

        uint256 initiateTs = block.timestamp;
        incrementTotalTransactionCount(); //increaments the count when function is triggered
        emit CustomMessageSent(userId, message, initiateTs, walletAddress);
    }

    function totalFiatPassAmount(uint256 passAmount)
        internal
        pure
        returns (uint256)
    {
        return passAmount;
    }

    function totalCryptoPassAmount(uint256 passAmount)
        internal
        pure
        returns (uint256)
    {
        return passAmount;
    }

    function totalCryptoPayments() external view onlyOwner returns (uint256) {
        return countCryptoPayments;
    }

    function totalCountFiatPending() external view onlyOwner returns (uint256) {
        return countFiatPending;
    }

    function totalCountOrderReceived()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return countOrderReceived;
    }

    function totaCountTransferred() external view onlyOwner returns (uint256) {
        return countTransferred;
    }

    function totalCountStandardPass()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return countStandardPass;
    }

    function totalCountPremimumPass()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return countPremimumPass;
    }

    function totalCountFiatPayments()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return countFiatPayments;
    }

    function totalCountCryptoPayments()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return countCryptoPayments;
    }

    // When ever there is an transaction that we writing to on-chain it gives total count of transactions
    function incrementTotalTransactionCount() internal onlyOwner {
        totalTransactionCount++;
    }

    // get total transaction count
    function getTotalTransactionCount()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return totalTransactionCount;
    }

    function getTransactionsForUser(string memory userId, address walletAddress)
        external
        view
        onlyOwner
        returns (UserOnRampData[] memory)
    {
        string[] storage userTxList = userTransactions[walletAddress];
        UserOnRampData[] memory transactions = new UserOnRampData[](
            userTxList.length
        );

        for (uint256 i = 0; i < userTxList.length; i++) {
            transactions[i] = useronrampdata[userTxList[i]];
        }

        return transactions;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getTransactionDataByRequestId(string memory orderId)
        external
        view
        returns (UserOnRampData memory)
    {
        // by using  the withdrawalRequests  to see  the data
        return onRampOrderId[orderId];
    }
}
