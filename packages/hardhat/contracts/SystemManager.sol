// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './DigitalCopy.sol';
import './Reviews.sol';
import './Users.sol';
import "hardhat/console.sol";

/**
 * @title Trusted Seller List Contract
 * @dev This contract manages trusted sellers and their associated digital copies
 */
contract SystemManager{

    /**
     * @dev Mapping to store whether a seller is trusted
     */
    mapping (address => bool) private SystemManagerMapping;

    /**
     * @dev Mapping to store digital copies minted by the contract
     */
    mapping (uint256 => address) private mintedDigitalCopiesMapping;

    /**
     * @dev Count of digital copies minted by the contract
     */
    uint256 private mintedDigitalCopyCount;

    /**
     * @dev Address of the contract owner
     */
    address private ownerAddress;
    
    /**
     * @dev Instance of the Users contract
     */
    Users private users;

    /**
     * @dev Instance of the Reviews contract
     */
    Reviews private reviews;

    /**
     *  @dev Event emitted when a new Users contract is deployed
     * 
     * @param contractAddress The address of the deployed contract
     */
    event DeployedUsersContract(address indexed contractAddress);

    /**
     *  @dev Event emitted when a new Reviews contract is deployed
     * 
     * @param contractAddress The address of the deployed contract
     */
    event DeployedReviewsContract(address indexed contractAddress);

    /**
     * @dev Event emitted when a DigitalCopy smart contract is deployed
     * 
     * @param contractAddress The address of the deployed contract
     */
    event DeployedDigitalCopyContract(address indexed contractAddress);

    /**
     * @dev Event emitted when a DigitalCopy smart contract changes mintability
     * 
     * @param contractAddress The address of the changed contract
     * @param mintability The status if a contract can mint or not
     */
    event StatusMintable(address indexed contractAddress, bool indexed mintability);

    /**
     * @dev Event emitted when a seller is added to the trusted seller list
     * 
     * @param addedAddress The address of the added trusted seller address
     */
    event AddedTrustedSeller(address indexed addedAddress);

    /**
     * @dev Event emitted when a seller is removed from the trusted seller list
     * 
     * @param removedAddress The address of the removed trusted seller address
     */
    event RemovedTrustedSeller(address indexed removedAddress);

    /**
     * @dev Modifier to ensure the function caller is authorized (matches the owner address)
     */
    modifier Authorized() {
        require(ownerAddress == msg.sender, "Not authorized");
        _;
    }

    /**
     * @dev Modifier to ensure there are existing digital copies minted by the contract
     */
    modifier ExistingDigitalCopies() {
        require(mintedDigitalCopyCount > 0, "There are no Digital Copy Contracts");
        _;
    }
    
    /**
     * @dev Constructor for the SystemManager contract, also initializes a Users contract and a Reviews contract
     */
    constructor() {
        ownerAddress = msg.sender;
        users = new Users();
        emit DeployedUsersContract(address(users));
        console.log("Address of the created Users contract", address(users));
        reviews = new Reviews();
        emit DeployedReviewsContract(address(reviews));
        console.log("Address of the created Review contract", address(reviews));
    }

    /**
     * @dev Adds a trusted seller
     * @param _address The address of the seller to be added
     */
    function add(address _address) public Authorized {
        SystemManagerMapping[_address] = true;
        emit AddedTrustedSeller(_address);
    }

    /**
     * @dev Removes a trusted seller
     * @param _address The address of the seller to be removed
     */
    function remove(address _address) public Authorized {
        SystemManagerMapping[_address] = false;
        emit RemovedTrustedSeller(_address);
    }

    /**
     * @dev Checks the trusted seller list for a given seller
     * @param _address The address of the seller to be checked
     * @return A boolean indicating whether the seller is trusted
     */
    function checkSystemManagerMapping(address _address) public view returns (bool) {
        return(SystemManagerMapping[_address]);
    }

    /**
     * @dev Deploys a new DigitalCopy contract
     */
    function deployDigitalCopy() public Authorized {
        DigitalCopy digitalCopy = new DigitalCopy(address(users));
        mintedDigitalCopiesMapping[mintedDigitalCopyCount] = address(digitalCopy);
        mintedDigitalCopyCount++;
        emit DeployedDigitalCopyContract(address(digitalCopy));
        console.log("Address of the created Digital Copy contract", address(digitalCopy));
    }

    function statusMintable(address _address, bool _status) public Authorized{
        require(digitalCopyAddressExist(_address), "This is not a valid DigitalCopy");
        DigitalCopy(_address).changeMintability(_status);
        emit StatusMintable(_address, _status);
    }

    /**
     * @dev Shows the addresses of all minted DigitalCopies
     * @return A list of addresses of the minted DigitalCopies
     */
    function showDigitalCopies() public view ExistingDigitalCopies returns(address[] memory) {
        address[] memory listOfAddresses = new address[](mintedDigitalCopyCount);
        for (uint256 i=0; i != mintedDigitalCopyCount; i++) {
            listOfAddresses[i] = (mintedDigitalCopiesMapping[i+1]);
        }
        return(listOfAddresses);
    }

    /**
     * @dev Checks whether a given DigitalCopy address exists in the minted DigitalCopies
     * @param _address The address of the DigitalCopy to be checked
     * @return A boolean indicating whether the DigitalCopy address exists
     */
    function digitalCopyAddressExist(address _address) public view ExistingDigitalCopies returns(bool) {
        for (uint256 i=0; i != mintedDigitalCopyCount; i++) {
            if (mintedDigitalCopiesMapping[i] == _address) {
                return(true);
            }
        }
        return(false);
    }

    /**
     * @dev Retrieves all items owned by a given address by iterating through all DigitalCopy contracts
     * @param _address The address of the owner
     * @return A two-dimentional list of item IDs owned by the address
     */
    function retrieveAllOwnedItems (address _address) public view ExistingDigitalCopies returns(uint256[][] memory) {
        require(_address == msg.sender, "Only owner can see all their owned items");
        uint256[][] memory allOwnedItems = new uint256[][](mintedDigitalCopyCount);
        uint256[] memory ownedItems;
        for (uint256 i=0; i != mintedDigitalCopyCount; i++){
            ownedItems = DigitalCopy(mintedDigitalCopiesMapping[i]).retriveOwnedItems(_address);
            allOwnedItems[i] = new uint256[](ownedItems.length);
            for (uint256 j=0; j != ownedItems.length; j++){
                allOwnedItems[i][j] = ownedItems[j];
            }
        }
        return(allOwnedItems);
    }


    /**
     * @dev Retrieves listing information for a given DigitalCopy and token ID
     * @param _address The address of the DigitalCopy contract
     * @param _digitalCopyID The ID of the Digital copy
     * @return Digital copy information, sum of user reviews, and count of user reviews
     */
    function retrieveListingInformation (address _address, uint256 _digitalCopyID) public view returns(DigitalCopy.digitalCopyInformationRetrival memory, uint256, uint256) {
        require(DigitalCopy(_address).getOwner(_digitalCopyID) == msg.sender, "You do not have access to this information");
        uint256 sum;
        uint256 count;
        DigitalCopy.digitalCopyInformationRetrival memory digitalCopyInformationRetrival = DigitalCopy(_address).retrieveInformationForDigitalCopy(_digitalCopyID);
        (sum, count) = reviews.getUserReviewSum(msg.sender);
        return(digitalCopyInformationRetrival, sum, count);
    }
}