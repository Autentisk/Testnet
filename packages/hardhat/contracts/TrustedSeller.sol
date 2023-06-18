// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './DigitalCopy.sol';
import './SystemManager.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import "hardhat/console.sol";

/**
 * @title TrustedSeller Contract
 * @dev This contract manages trusted sellers in a retailer markets
 */
contract TrustedSeller is IERC721Receiver {

    /**
     * @dev Mapping to store approved addresses of trusted sellers
     */
    mapping (address => bool) private trustedSellerAddressMapping;

    /**
     * @dev Mapping to store a hash of minted Digital Copies
     */
    mapping (bytes32 => bool) private mintedDigitalCopiesMapping;

    /**
     * @dev The name of this trusted seller
     */
    string private trustedSellerName;

    /**
     * @dev Current instance of DigitalCopy contract
     */
    DigitalCopy private digitalCopy;

    /**
     * @dev Instance of the SystemManager contract
     */
    SystemManager private systemManager;

    /**
     * @dev Emitted when a purchase is made.
     *
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     */
    event Purchase(address indexed buyer, address indexed seller);

    /**
     * @dev Emitted when a trusted address is added.
     *
     * @param addedAddress The address that has been added to the trusted list.
     */
    event AddedTrustedAddress(address indexed addedAddress);

    /**
     * @dev Emitted when a trusted address is removed.
     *
     * @param removedAddress The address that has been removed from the trusted list.
     */
    event RemovedTrustedAddress(address indexed removedAddress);

    /**
     * @dev Modifier to ensure the function caller is authorized
     */
    modifier Authorized() {
        require(trustedSellerAddressMapping[msg.sender] == true, "You are not Authorized");
        _;
    }

    /**
     * @notice Constructs a new TrustedSeller
     * @dev Initializes trusted seller address mapping and name
     * @param _trustedSellerName The name of the trusted seller
     * @param _systemManager Address of the SystemManager contract
     */
    constructor(string memory _trustedSellerName, address _systemManager) {
        trustedSellerAddressMapping[msg.sender] = true;
        systemManager = SystemManager(_systemManager);
        trustedSellerName = _trustedSellerName;
    }

    /**
     * @dev Function to return the name of the Trusted Seller
     * @return The name of the Trusted Seller
     */
    function retrieveName() public view returns(string memory){
        return(trustedSellerName);
    }

    /**
     * @notice Enables a buyer to purchase a digital copy
     * @dev Mints a new DigitalCopy and transfers it to the buyer
     * @param _name Name of the item being bought
     * @param _price Price of the item
     * @param _category Category of the item
     * @param _brand Brand of the item
     * @param _serialnumber Serial number of the item
     * @param _buyersAddress Address of the buyer
     */
    function purchase(string calldata _name, string calldata _price, string calldata _category, string calldata _brand, string calldata _serialnumber, address _buyersAddress) public Authorized {
        require(digitalCopy.existingUser(_buyersAddress), "This buyer does not have a user account");
        bytes32 hashedDigitalCopyInformation = keccak256(bytes.concat(bytes(_name), bytes(_brand), bytes(_serialnumber)));
        require(!mintedDigitalCopiesMapping[hashedDigitalCopyInformation], "This product has already been minted");
        uint256 digitalCopyID = digitalCopy.mint(_name, _price, _category, _brand, _serialnumber);
        mintedDigitalCopiesMapping[hashedDigitalCopyInformation] = true;
        digitalCopy.transfer(digitalCopyID, _buyersAddress, _price);
        emit Purchase (msg.sender, _buyersAddress);  
    }

    /**
     * @notice ERC721 token received hook
     * @dev Ensures the contract can receive ERC721 tokens
     * @return bytes4 selector for the onERC721Received interface
     */
    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Adds a new trusted address
     * @dev Updates the trustedSellerAddressMapping
     * @param _address The address to be added
     */
    function addTrustedAddress(address _address) public Authorized {
        trustedSellerAddressMapping[_address] = true;
        emit AddedTrustedAddress(_address);
    }

    /**
     * @notice Removes a trusted address
     * @dev Updates the trustedSellerAddressMapping
     * @param _address The address to be removed
     */
    function removeTrustedAddress(address _address) public Authorized {
        trustedSellerAddressMapping[_address] = false;
        emit RemovedTrustedAddress(_address);
    }

    /**
     * @notice Changes the DigitalCopy contract address
     * @dev Updates the digitalCopy variable to point to a new contract
     * @param _address The address of the new DigitalCopy contract
     */
    function changeDigitalCopyContract(address _address) public Authorized {
        require(systemManager.digitalCopyAddressExist(_address), "This address is not a Digital Copy address");
        digitalCopy = DigitalCopy(_address);
    }

    /**
     * @notice Returns the current DigitalCopy contract address
     * @dev Displays the digitalCopy variable
     * @return Address of the DigitalCopy contract
     */
    function showDigitalCopyContract() external view Authorized returns(address){
        return(address(digitalCopy));
    }
}