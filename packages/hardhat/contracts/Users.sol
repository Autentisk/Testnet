// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title User Management Contract
 * @dev This contract manages user information using their Ethereum addresses
 */
contract Users {

    /**
     * @dev Mapping to store whether a user with a particular address already exists
     */
    mapping(address => bool) private existingUsersMapping;

    /**
     * @dev Mapping to store user information against a hashed value of their name and personal identifier
     */
    mapping(bytes32 => User) private userInformationMapping;

    /**
     * @dev Struct to hold user information
     */
    struct User {
        string name;
        address walletAddress;
    }

    /**
     * @dev Emitted when a new user is added to the system.
     *
     * @param userAddress The Ethereum address of the added user.
     */
    event AddedUser(address indexed userAddress);

    /**
     * @dev Modifier to ensure the user does not already exist
     */
    modifier userDoesNotExist() {
        require(!existingUsersMapping[msg.sender], "User already exist");
        _;
    }

    /**
     * @dev Constructor for the Users contract
     */
    constructor() {
    }

    /**
     * @notice Creates a new user
     * @dev This function creates a new user only if the user doesn't already exist
     * @param _name The name of the user
     * @param _personalIdentifier The personal identifier of the user
     */
    function createUser(string memory _name, string memory _personalIdentifier) public userDoesNotExist {
        bytes32 hashedInformation = keccak256(bytes.concat(bytes(_name), bytes(_personalIdentifier)));
        User memory _user = User(_name, msg.sender);
        existingUsersMapping[msg.sender] = true;
        userInformationMapping[hashedInformation] = _user;
        emit AddedUser(msg.sender);
    }

    /**
     * @notice Checks if a user exists
     * @dev This function checks if a user with a specific address already exists
     * @param _address The address of the user to check
     * @return A boolean indicating whether the user exists
     */
    function userExist(address _address) public view returns(bool) {
        return(existingUsersMapping[_address]);
    }
}