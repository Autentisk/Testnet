// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './DigitalCopy.sol';


import "hardhat/console.sol";

/**
 * @title Reviews Contract
 * @dev This contract manages reviews for transactions between buyers and sellers
 */
contract Reviews {

    /**
     * @dev Mapping to store user reviews
     */
    mapping(address => Review[]) private userReviewsMapping;

    /**
     * @dev Mapping to store reviewed transactions
     */
    mapping(bytes32 => bool) private transactionReviewedMapping;

    /**
     * @dev The address of the SystemManager contract
     */
    address private systemManagerAddress;

    /**
     * @dev Review struct to hold review information
     */
    struct Review {
        address seller;
        address buyer;
        uint8 rating;
        address digitalCopy;
        uint256 digitalCopyID;
        bytes32 transactionID;
        string text;
    }

    /**
     * @dev Emitted when a new review is added to the system.
     *
     * @param transactionID The transaction hash of the transaction that has been reviewed.
     */
    event AddedReview(bytes32 indexed transactionID);

    /**
     * @dev Modifier to ensure a review does not already exist for a transaction
     * @param transactionID The ID of the transaction
     */
    modifier nonExistingReview(bytes32 transactionID) {
        require(!transactionReviewedMapping[transactionID], "There has already been a review of this transaction");
        _;
    }

    /**
     * @dev Modifier to ensure the function caller is authorized (is the Trusted Seller List)
     */
    modifier OnlySystemManager() {
        require(msg.sender == systemManagerAddress);
        _;
    }

    /**
     * @dev Modifier to ensure the function caller owns the digital copy being reviewed
     * @param _address The address of the owner of the digital copy
     * @param _digitalCopyID The token ID of the digital copy
     */
    modifier ownerOfNFT(address _address, uint256 _digitalCopyID) {
        require(msg.sender == DigitalCopy(_address).getOwner(_digitalCopyID), "You do are not autorized to comment on this product");
        _;
    }

    /**
     * @dev Constructor for the Reviews contract
     */
    constructor() {
        systemManagerAddress = msg.sender;        
    }


    /**
     * @notice Submits a new review
     * @dev Creates a new Review struct and stores it in userReviewsMapping
     * @param _seller The address of the seller
     * @param rating The rating given by the buyer
     * @param _digitalCopy The address of the DigitalCopy contract
     * @param _digitalCopyID The token ID of the digital copy
     * @param _transactionID The ID of the transaction
     * @param _text The text of the review
     */
    function newReview(address _seller, uint8 rating, address _digitalCopy, uint256 _digitalCopyID, bytes32 _transactionID, string memory _text) public 
    ownerOfNFT(_digitalCopy, _digitalCopyID) nonExistingReview(_transactionID) {
        require(rating<6 && rating>0, "Not a valid rating");
        Review memory _review = Review(_seller, msg.sender, rating, _digitalCopy, _digitalCopyID, _transactionID, _text);
        userReviewsMapping[_seller].push(_review);
        emit AddedReview(_transactionID);
    }

    /**
     * @notice Retrieves a user's reviews
     * @dev Returns the array of reviews for a user from userReviewsMapping
     * @param _address The address of the user
     * @return An array of Review structs containing the user's reviews
     */
    function getUserReviews(address _address) public view OnlySystemManager returns(Review[] memory) {
        return(userReviewsMapping[_address]);
    }

    /**
     * @notice Calculates the sum and count of a user's reviews
     * @dev Iterates through a user's reviews to calculate sum and count of ratings
     * @param _address The address of the user
     * @return Two uint256 values representing the sum and count of the user's reviews
     */
    function getUserReviewSum(address _address) public view OnlySystemManager returns(uint256, uint256) {
        if (userReviewsMapping[_address].length == 0) {
            return(0,0);
        }
        uint256 sum;
        uint256 count;
        for(uint256 i=0; i != userReviewsMapping[_address].length; i++) {
            sum += userReviewsMapping[_address][i].rating;
            count++;
        }
        return(sum, count);
    }

}