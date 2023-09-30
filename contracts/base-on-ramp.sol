// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OnRampData is
   Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct timeStampData {
        uint256 withdrawInitiatedTimeStamp;
        uint256 fiatTimeStamp;
        uint256 cryptoTimeStamp;
        uint256 OrderReceivedTimeStamp;
        uint256 cryptoReceivedTimeStamp;
        uint256 payoutSuccessTimeStamp;
    }

    struct UserOnRampData {
        address walletAddress;
        string paymentType;
        uint256 timestamp;
        string onMetaTransactionID;
        string userId;
        Status status;
        timeStampData[] allTimeStamps;
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
    uint256 private countFiatPending;
    uint256 private countOrderReceived;
    uint256 private countTransferred;
    uint256 private countCompleted;
    uint256 private countFiatPayments;
    uint256 private countCryptoPayments;
    uint256 public totalFiatSpent;
    uint256 public totalCryptoSpent;

constructor() {
    totalTransactionCount = 0;
}

    event upgradingPass(
        string indexed userId,
        address walletAddress,
        string paymentType,
        uint256 allTimeStamps
    );
    event fiatTransaction(
        string indexed userId,
        address walletAddress,
        string paymentType,
        uint256 fiatTimeStamp
    );
    event cryptoTransaction(
        string indexed userId,
        address walletAddress,
        string paymentType,
        uint256 allTimeStamps,
        uint256 passAmount
    );
    event standardPassPurchase(
        string indexed userId,
        address walletAddress,
        string passType,
        uint256 timestamp,
        uint256 passAmount
    );
    event premiumPassPurchase(
        string indexed userId,
        address walletAddress,
        string passType,
        uint256 timestamp,
        uint256 passAmount
    );
    event fiatPendingCreated(
        string indexed userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string onMetaTransactionID,
        uint256 allTimeStamps
    );
    event orderReceivedCreated(
        string indexed userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string onMetaTransactionID,
        uint256 allTimeStamps
    );
    event transferredCreated(
        string indexed userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string onMetaTransactionID,
        uint256 allTimeStamps
    );
    event completedCreated(
        string indexed userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string onMetaTransactionID,
        uint256 allTimeStamps
    );
    event CustomMessageSent(
        string indexed userId,
        string message,
        uint256 allTimeStamps,
        address walletAddress
    );

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function upgradePass(
        string memory userId,
        address walletAddress,
        string memory paymentType
    ) external nonReentrant  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        // require(bytes(paymentType).length > 0, "Invalid payment mode");

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        // data.paymentType = paymentType;
        uint256 allTimeStamps = block.timestamp;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit upgradingPass(userId, walletAddress, paymentType, allTimeStamps); //Emits the data specified in the parameters.
    }

    function standardPass(
        string memory userId,
        address walletAddress,
        string memory passType,
        uint256 passAmount
    ) external  nonReentrant {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(bytes(passType).length > 0, "Invalid passType ");
        require(passAmount > 0, "Pass amount should not be less the 0");

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        data.passType = passType;
        data.passAmount = passAmount;
        uint256 allTimeStamps = block.timestamp;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit standardPassPurchase(
            userId,
            walletAddress,
            passType,
            allTimeStamps,
            passAmount
        );
    }

    function premiumPass(
        string memory userId,
        address walletAddress,
        string memory passType,
        uint256 passAmount
    ) external  nonReentrant {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(bytes(passType).length > 0, "Invalid passType ");
        require(passAmount > 0, "Pass amount should not be less the 0");

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        data.passType = passType;
        data.passAmount = passAmount;
        uint256 allTimeStamps = block.timestamp;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit premiumPassPurchase(
            userId,
            walletAddress,
            passType,
            allTimeStamps,
            passAmount
        );
    }

    function fiat(
        string memory userId,
        address walletAddress,
        string memory paymentType,
        string memory passType,
        uint256 passAmount
    ) external nonReentrant  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(bytes(paymentType).length > 0, "Invalid payment mode");
        require(bytes(passType).length > 0, "Invalid passType ");
        require(passAmount > 0, "Pass amount should not be less the 0");

        UserOnRampData storage data = useronrampdata[userId];

        data.walletAddress = walletAddress;
        data.paymentType = paymentType;
        data.passType = passType;
        data.passAmount = passAmount;
        uint256 fiatTimeStamp = block.timestamp;
        countFiatPayments++;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit fiatTransaction(userId, walletAddress, paymentType, fiatTimeStamp);
    }

    function fiatPending(
        string memory userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string memory onMetaTransactionID
    ) external  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(
            bytes(onMetaTransactionID).length > 0,
            "onMetaTransactionID cannot be empty"
        );

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        uint256 allTimeStamps = block.timestamp;
        countFiatPending++;
        data.status = status;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit fiatPendingCreated(
            userId,
            walletAddress,
            passAmount,
            status,
            onMetaTransactionID,
            allTimeStamps
        ); //Emits the data specified in the parameters.
    }

    function orderReceived(
        string memory userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string memory onMetaTransactionID
    ) external  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(
            bytes(onMetaTransactionID).length > 0,
            "onMetaTransactionID cannot be empty"
        );

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        uint256 allTimeStamps = block.timestamp;
        data.onMetaTransactionID = onMetaTransactionID;
        data.status = status;
        countOrderReceived++;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered
        emit orderReceivedCreated(
            userId,
            walletAddress,
            passAmount,
            status,
            onMetaTransactionID,
            allTimeStamps
        ); //Emits the data specified in the parameters.
    }

    function Transferred(
        string memory userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string memory onMetaTransactionID
    ) external  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(
            bytes(onMetaTransactionID).length > 0,
            "onMetaTransactionID cannot be empty"
        );

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        uint256 allTimeStamps = block.timestamp;
        data.status = status;
        countTransferred++;
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered
        emit transferredCreated(
            userId,
            walletAddress,
            passAmount,
            status,
            onMetaTransactionID,
            allTimeStamps
        );
    }

    function Completed(
        string memory userId,
        address walletAddress,
        uint256 passAmount,
        Status status,
        string memory onMetaTransactionID
    ) external  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(passAmount > 0, "Pass amount should not be less the 0");
        require(
            bytes(onMetaTransactionID).length > 0,
            "onMetaTransactionID cannot be empty"
        );

        UserOnRampData storage data = useronrampdata[userId];
        data.walletAddress = walletAddress;
        uint256 allTimeStamps = block.timestamp;
        data.status = status;
        countCompleted++;
        userTransactions[walletAddress].push(userId);
        totalFiatSpent += totalFiatPassAmount(passAmount); // Increment the total fiat spent
        incrementTotalTransactionCount(); //increaments the count when function is triggered
        emit completedCreated(
            userId,
            walletAddress,
            passAmount,
            status,
            onMetaTransactionID,
            allTimeStamps
        );
    }

    function crypto(
        string memory userId,
        address walletAddress,
        string memory paymentType,
        string memory passType,
        uint256 passAmount
    ) external nonReentrant  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(walletAddress != address(0), "Invalid wallet address");
        require(
            bytes(paymentType).length > 0,
            "Invalid payment mode Either INR or USDT"
        );
        require(bytes(passType).length > 0, "Invalid passType ");
        require(passAmount > 0, "Pass amount should not be less the 0");
        UserOnRampData storage data = useronrampdata[userId];

        data.walletAddress = walletAddress;
        data.paymentType = paymentType;
        data.passType = passType;
        data.passAmount = passAmount;
        uint256 allTimeStamps = block.timestamp;
        countCryptoPayments++;
        totalCryptoSpent += totalCryptoPassAmount(passAmount);
        userTransactions[walletAddress].push(userId);
        incrementTotalTransactionCount(); //increaments the count when function is triggered

        emit cryptoTransaction(
            userId,
            walletAddress,
            paymentType,
            allTimeStamps,
            passAmount
        ); //Emits the data specified in the parameters.
    }

    function onCancled(
        string memory userId,
        string memory message,
        address walletAddress
    ) external  {
        require(bytes(userId).length > 0, "Invalid user ID");
        require(bytes(message).length > 0, "Message cannot be empty");
        require(walletAddress != address(0), "Invalid wallet address");

        uint256 allTimeStamps = block.timestamp;
        incrementTotalTransactionCount(); //increaments the count when function is triggered
        emit CustomMessageSent(userId, message, allTimeStamps, walletAddress);
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

    function totalCryptoPayments() external onlyOwner view returns (uint256) {
        return countCryptoPayments;
    }
        function totalCountFiatPending() external onlyOwner view returns (uint256) {
        return countFiatPending;
    }
        function totalCountOrderReceived() external onlyOwner view returns (uint256) {
        return countOrderReceived;
    }
        function totaCountTransferred() external onlyOwner view returns (uint256) {
        return countTransferred;
    }
            function totaCountFiatPayments() external onlyOwner  view returns (uint256) {
        return countFiatPayments;
    }
            function totaCountCryptoPayments() external onlyOwner view returns (uint256) {
        return countCryptoPayments;
    }

    // When ever there is an transaction that we writing to on-chain it gives total count of transactions
function incrementTotalTransactionCount() internal onlyOwner {
    totalTransactionCount++;
}
// get total transaction count 
function getTotalTransactionCount() external onlyOwner view returns (uint256) {
    return totalTransactionCount;
}

// function getCompletedTransactions(string memory userId, address walletAddress)
//     external
//     view
//     returns (string[] memory)
// {
//     require(bytes(userId).length > 0, "Invalid user ID");
//     require(walletAddress != address(0), "Invalid wallet address");

//     string[] storage transactions = userTransactions[walletAddress];
//     string[] memory completedTransactions = new string[](transactions.length);
//     uint256 completedCount = 0;

//     for (uint256 i = 0; i < transactions.length; i++) {
//         string memory txUserId = transactions[i];
//         if (
//             keccak256(abi.encodePacked(useronrampdata[txUserId].userId)) ==
//             keccak256(abi.encodePacked(userId)) &&
//             useronrampdata[txUserId].status == Status.Completed
//         ) {
//             completedTransactions[completedCount] = txUserId;
//             completedCount++;
//         }
//     }

//     // Resize the array to remove any unused slots
//     assembly {
//         mstore(completedTransactions, completedCount)
//     }

//     return completedTransactions;
// }


function getTransactionsForUser(string memory userId, address walletAddress) external onlyOwner view returns (UserOnRampData[] memory) {
    string[] storage userTxList = userTransactions[walletAddress];
    UserOnRampData[] memory transactions = new UserOnRampData[](userTxList.length);

    for (uint256 i = 0; i < userTxList.length; i++) {
        transactions[i] = useronrampdata[userTxList[i]];
    }

    return transactions;
}

}
