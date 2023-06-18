// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./SystemManager.sol";
import "./TrustedSeller.sol";
import "./Users.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title DigitalCopy Contract
 * @dev Contract for creating, transferring, and querying digital copies of products
 */
contract DigitalCopy is ERC721 {
    /**
     * @dev Instance of the SystemManager contract
     */
    SystemManager private systemManager = SystemManager(/*YOUR_SYSTEMMANAGER_ADDRESS*/);


    /**
     * @dev Mapping to store the owned tokens per user
     */
    mapping(address => uint256[]) private ownedTokensMapping;

    /**
     * @dev Mapping to store the information per digital copy
     */
    mapping(uint256 => digitalCopyInformation)
        private digitalCopyInformationMapping;

    /**
     * @dev Instance of the Users contract
     */
    Users private users;

    /**
     * @dev Variable to keep track of number of minted digital copies
     */
    uint256 private digitalCopyID;

    /**
     * @dev A variable which controls if more ERC721 tokens can be minted, when deployed allowed to mint
     */
    bool private mintable = true;

    /**
     * @dev Struct to hold information related to a digital copy
     */
    struct digitalCopyInformation {
        string name;
        string price;
        address owner;
        string category;
        string brand;
        string serialNumber;
        uint256 time;
        mapping(uint256 => uint256) timeHistory;
        mapping(uint256 => string) priceHistory;
        mapping(uint256 => address) ownerHistory;
        uint256 transfers;
        bool forSale;
    }

    /**
     * @dev Struct to retrieve information of a digital copy
     */
    struct digitalCopyInformationRetrival {
        string name;
        string price;
        address owner;
        string category;
        string brand;
        string serialNumber;
        uint256 time;
        uint256[] timeHistory;
        string[] priceHistory;
        address[] ownerHistory;
        uint256 transfers;
        bool forSale;
    }

    /**
     * @dev Emitted when a new Digital Copy is minted.
     *
     * @param digitalCopyID The unique identifier of the minted Digital Copy.
     */
    event MintedDigitalCopy(uint256 indexed digitalCopyID);

    /**
     * @dev Emitted when a Digital Copy is transferred from a seller to a buyer.
     *
     * @param seller The address of the seller.
     * @param buyer The address of the buyer.
     * @param digitalCopyID The unique identifier of the Digital Copy being transferred.
     */
    event TransferredDigitalCopy(
        address indexed seller,
        address indexed buyer,
        uint256 indexed digitalCopyID
    );

    /**
     * @dev Emitted when a Digital Copy is burned.
     *
     * @param digitalCopyID The unique identifier of the burned Digital Copy.
     */
    event BurnedDigitalCopy(uint256 indexed digitalCopyID);

    /**
     * @dev Modifier to ensure the function caller is a trusted seller
     */
    modifier onlySystemManager() {
        require(msg.sender == address(systemManager), "Not authorized");
        _;
    }

    /**
     * @dev Modifier to ensure the function caller is a trusted seller
     */
    modifier onlyTrustedSeller() {
        require(
            systemManager.checkSystemManagerMapping(msg.sender),
            "Not authorized"
        );
        _;
    }

    /**
     * @dev Modifier to ensure the function caller is the owner of a specific digital copy
     * @param _digitalCopyID The ID of the digital copy
     */
    modifier onlyOwner(uint256 _digitalCopyID) {
        require(msg.sender == ownerOf(_digitalCopyID), "Not yours");
        _;
    }

    /**
     * @dev Modifier to ensure a specific digital copy is for sale
     * @param _digitalCopyID The ID of the digital copy
     */
    modifier forSale(uint256 _digitalCopyID) {
        require(isItemForSale(_digitalCopyID), "Item not for sale");
        _;
    }

    /**
     * @dev Modifier to ensure a that the contract can still mint
     */
    modifier Mintable() {
        require(mintable, "Item not for sale");
        _;
    }

    /**
     * @notice Constructs a new DigitalCopy
     * @dev Checks the trusted seller list and initializes the users
     */
    constructor(
        address _users
    ) ERC721("DigitalCopyAutentisk", "DCA") onlySystemManager {
        users = Users(_users); //Set as the adderess of the User smart contract
    }

    /**
     * @notice Mints a new digital copy
     * @dev Stores the provided details and sets the digital copy as for sale
     * @param _name The name of the product
     * @param _price The price of the product
     * @param _category category of the product
     * @param _brand brand of the product
     * @param _serialnumber The serial number of the product
     * @return mintedDigitalCopyID The ID of the newly minted digital copy
     */
    function mint(
        string calldata _name,
        string calldata _price,
        string calldata _category,
        string calldata _brand,
        string calldata _serialnumber
    ) public onlyTrustedSeller Mintable returns (uint256 mintedDigitalCopyID) {
        mintedDigitalCopyID = digitalCopyID++;
        _safeMint(msg.sender, mintedDigitalCopyID);
        digitalCopyInformation
            storage _digitalCopyInformation = digitalCopyInformationMapping[
                mintedDigitalCopyID
            ];
        _digitalCopyInformation.name = _name;
        _digitalCopyInformation.price = _price;
        _digitalCopyInformation.owner = msg.sender;
        _digitalCopyInformation.category = _category;
        _digitalCopyInformation.brand = _brand;
        _digitalCopyInformation.serialNumber = _serialnumber;
        _digitalCopyInformation.time = block.timestamp;
        _digitalCopyInformation.timeHistory[
            _digitalCopyInformation.transfers
        ] = block.timestamp;
        _digitalCopyInformation.priceHistory[
            _digitalCopyInformation.transfers
        ] = _price;
        _digitalCopyInformation.ownerHistory[
            _digitalCopyInformation.transfers
        ] = msg.sender;
        _digitalCopyInformation.forSale = true;
        _digitalCopyInformation.transfers++;
        ownedTokensMapping[msg.sender].push(mintedDigitalCopyID);
        emit MintedDigitalCopy(mintedDigitalCopyID);
    }

    /**
     * @notice Transfers a digital copy to a new owner
     * @dev Updates the details of the digital copy and changes ownership
     * @param _digitalCopyID The ID of the digital copy to transfer
     * @param _buyersAddress The address of the new owner
     * @param _price The new price of the digital copy
     */
    function transfer(
        uint256 _digitalCopyID,
        address _buyersAddress,
        string memory _price
    ) public forSale(_digitalCopyID) {
        _requireMinted(_digitalCopyID);
        require(
            existingUser(_buyersAddress),
            "This buyer does not have a user account"
        );
        _safeTransfer(
            msg.sender,
            _buyersAddress,
            _digitalCopyID,
            bytes(_price)
        );
        digitalCopyInformation storage _digitalCopyInformation = digitalCopyInformationMapping[_digitalCopyID];
        _digitalCopyInformation.price = _price;
        _digitalCopyInformation.owner = _buyersAddress;
        _digitalCopyInformation.time = block.timestamp;
        _digitalCopyInformation.timeHistory[_digitalCopyInformation.transfers] = block.timestamp;
        _digitalCopyInformation.priceHistory[_digitalCopyInformation.transfers] = _price;
        _digitalCopyInformation.ownerHistory[
            _digitalCopyInformation.transfers
        ] = msg.sender;
        _digitalCopyInformation.transfers++;
        _digitalCopyInformation.forSale = false;
        uint256[] memory fromOwnedTokens = ownedTokensMapping[msg.sender];  //Fjerne denne?
        uint256 fromIndex;
        for (uint256 i = 0; i < fromOwnedTokens.length; i++) {
            if (fromOwnedTokens[i] == _digitalCopyID) {
                fromIndex = i;
                break;
            }
        }
        ownedTokensMapping[msg.sender][fromIndex] = ownedTokensMapping[msg.sender][fromOwnedTokens.length - 1];
        ownedTokensMapping[msg.sender].pop();
        //Update the mapping
        ownedTokensMapping[_buyersAddress].push(_digitalCopyID);
        emit TransferredDigitalCopy(msg.sender, _buyersAddress, _digitalCopyID);
    }

    /**
     * @notice Returns the owner of a specific digital copy
     * @dev Returns the address of the owner of a digital copy
     * @param _digitalCopyID The ID of the digital copy
     * @return The address of the owner
     */
    function getOwner(uint256 _digitalCopyID) public view returns (address) {
        return ownerOf(_digitalCopyID);
    }

    /**
     * @notice Burns a digital copy
     * @dev Deletes the digital copy from the contract
     * @param _digitalCopyID The ID of the digital copy to burn
     */
    function burn(uint256 _digitalCopyID) public onlyOwner(_digitalCopyID) {
        _burn(_digitalCopyID);
        uint256[] memory fromOwnedTokens = ownedTokensMapping[msg.sender];  //Fjerne denne?
        uint256 fromIndex;
        for (uint256 i = 0; i < fromOwnedTokens.length; i++) {
            if (fromOwnedTokens[i] == _digitalCopyID) {
                fromIndex = i;
                break;
            }
        }
        ownedTokensMapping[msg.sender][fromIndex] = ownedTokensMapping[msg.sender][fromOwnedTokens.length - 1];
        ownedTokensMapping[msg.sender].pop();
        emit BurnedDigitalCopy(_digitalCopyID);
    }

    /**
     * @notice Retrieves information for a specific digital copy
     * @dev Returns the details and history of a digital copy
     * @param _digitalCopyID The ID of the digital copy
     * @return The details and history of the digital copy
     */
    function retrieveInformationForDigitalCopy(
        uint256 _digitalCopyID
    ) public view returns (digitalCopyInformationRetrival memory) {
        _requireMinted(_digitalCopyID);
        require(
            isItemForSale(_digitalCopyID) ||
                msg.sender == getOwner(_digitalCopyID),
            "You do not have access to this information"
        );
        uint256 numberOfTransfers = digitalCopyInformationMapping[
            _digitalCopyID
        ].transfers;
        uint256[] memory _timeHistory = new uint256[](numberOfTransfers);
        string[] memory _priceHistory = new string[](numberOfTransfers);
        address[] memory _ownerHistory = new address[](numberOfTransfers);
        for (uint256 i; i != numberOfTransfers; i++) {
            _timeHistory[i] = digitalCopyInformationMapping[_digitalCopyID]
                .timeHistory[i];
            _priceHistory[i] = digitalCopyInformationMapping[_digitalCopyID]
                .priceHistory[i];
            _ownerHistory[i] = digitalCopyInformationMapping[_digitalCopyID]
                .ownerHistory[i];
        }
        return (
            digitalCopyInformationRetrival(
                digitalCopyInformationMapping[_digitalCopyID].name,
                digitalCopyInformationMapping[_digitalCopyID].price,
                digitalCopyInformationMapping[_digitalCopyID].owner,
                digitalCopyInformationMapping[_digitalCopyID].category,
                digitalCopyInformationMapping[_digitalCopyID].brand,
                digitalCopyInformationMapping[_digitalCopyID].serialNumber,
                digitalCopyInformationMapping[_digitalCopyID].time,
                _timeHistory,
                _priceHistory,
                _ownerHistory,
                digitalCopyInformationMapping[_digitalCopyID].transfers,
                digitalCopyInformationMapping[_digitalCopyID].forSale
            )
        );
    }

    /**
     * @notice Retrieves the owned items of a specific address
     * @dev Returns the list of digital copies owned by an address
     * @param _address The address to the owner
     * @return The list of owned digital copies
     */
    function retriveOwnedItems(
        address _address
    ) public view onlySystemManager returns (uint256[] memory) {
        return (ownedTokensMapping[_address]);
    }

    /**
     * @notice Checks if a user exists
     * @dev Returns a boolean indicating the existence of a user
     * @param _address The address of the user
     * @return True if the user exists, False otherwise
     */
    function existingUser(address _address) public view returns (bool) {
        return (users.userExist(_address));
    }

    /**
     * @notice Checks if a digital copy is for sale
     * @dev Returns a boolean indicating if a digital copy is for sale
     * @param _digitalCopyID The ID of the digital copy
     * @return True if the digital copy is for sale, False otherwise
     */
    function isItemForSale(uint256 _digitalCopyID) public view returns (bool) {
        return (digitalCopyInformationMapping[_digitalCopyID].forSale == true);
    }

    /**
     * @notice Marks a digital copy as for sale
     * @dev Updates the status of a digital copy to be for sale
     * @param _digitalCopyID The ID of the digital copy
     */
    function putItemForSale(
        uint256 _digitalCopyID
    ) public onlyOwner(_digitalCopyID) {
        digitalCopyInformationMapping[_digitalCopyID].forSale = true;
    }

    /**
     * @notice Marks a digital copy as not for sale
     * @dev Updates the status of a digital copy to not be for sale
     * @param _digitalCopyID The ID of the digital copy
     */
    function putItemNotForSale(
        uint256 _digitalCopyID
    ) public onlyOwner(_digitalCopyID) {
        digitalCopyInformationMapping[_digitalCopyID].forSale = false;
    }

    /**
     * @notice Changes if the contract can mint
     * @dev Updates the boolean status of the mintable variable
     * @param _boolean The status of the change in mintability (True if allowed to mint)
     */
    function changeMintability(bool _boolean) public onlySystemManager {
        mintable = _boolean;
    }
}
