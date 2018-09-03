pragma solidity 0.4.24;

// Contracts
import "../../RocketBase.sol";
import "../node/RocketNodeContract.sol";
// Interfaces
import "../../interface/settings/RocketNodeSettingsInterface.sol";
import "../../interface/settings/RocketMinipoolSettingsInterface.sol";



/// @title Handles node API methods in the Rocket Pool infrastructure
/// @author David Rugendyke

contract RocketNodeAPI is RocketBase {

    /*** Libs  *****************/

    using SafeMath for uint;


    /*** Contracts *************/

    RocketNodeSettingsInterface rocketNodeSettings = RocketNodeSettingsInterface(0);                        // Settings for the nodes
    RocketMinipoolSettingsInterface rocketMinipoolSettings = RocketMinipoolSettingsInterface(0);            // Settings for the minipools 
   


    /*** Events ****************/

    event NodeAdd (
        address indexed ID,
        address indexed contractAddress,
        uint256 created
    );


    // TODO: Remove Flag Events
    event FlagString (
        string flag
    );

    event FlagUint (
        uint256 flag
    );

       
    /*** Modifiers *************/

    /// @dev Only passes if the user calling it is a registered node
    modifier onlyNode(address _nodeAddress) {
        require(rocketStorage.getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Node address does not exist.");
        _;
    }

    /// @dev Only passes if the supplied minipool duration is valid
    /// @param _durationID The ID that determines the minipool duration
    modifier onlyValidDuration(string _durationID) {
        // Get our minipool settings
        rocketMinipoolSettings = RocketMinipoolSettingsInterface(getContractAddress("rocketMinipoolSettings"));
        // Check to verify the supplied mini pool staking time id is legit, it will revert if not
        rocketMinipoolSettings.getMinipoolStakingDuration(_durationID);
        _;
    }
  
       
    /*** Constructor *************/

    /// @dev rocketNode constructor
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
        // Version
        version = 1;
    }


    /*** Getters *************/

    /// @dev Returns the contract address where the nodes ether/rpl deposits will reside
    /// @return address The address of the contract
    function getContract(address _nodeAddress) public view returns (address) {
        rocketStorage.getAddress(keccak256(abi.encodePacked("node.contract", _nodeAddress)));
    }

    /// @dev Returns the timezone of the node as Country/City eg America/New_York
    /// @return string The set timezone of this node
    function getTimezoneLocation(address _nodeAddress) public view returns (string) {
        rocketStorage.getString(keccak256(abi.encodePacked("node.timezone.location", _nodeAddress)));
    }

    /// @dev Returns the amount of RPL required for a single ether
    /// @param _durationID The ID that determines which pool duration
    function getRPLRatio(string _durationID) public onlyValidDuration(_durationID) returns(uint256) { 
        // TODO: Add in actual calculations using the quintic formula ratio - returns a 1:1.5 atm
        uint256 rplRatio = 1.5 ether;
        return rplRatio;
    }

    /// @dev Returns the amount of RPL required to make an ether deposit based on the current network utilisation
    /// @param _weiAmount The amount of ether the node wishes to deposit
    /// @param _durationID The ID that determines which pool duration
    function getRPLRequired(uint256 _weiAmount, string _durationID) public view onlyValidDuration(_durationID) returns(uint256) { 
        
        // TODO: Add in actual calculations using the quintic formula ratio - returns a 1:1 atm
        return _weiAmount;
    }


    /// @dev Checks if the deposit reservations parameters are correct for a successful reservation
    /// @param _from  The address sending the deposit
    /// @param _value The amount being deposited
    /// @param _durationID The ID that determines which pool the user intends to join based on the staking blocks of that pool (3 months, 6 months etc)
    /// @param _rplRatio  The amount of RPL required per ether
    /// @param _lastDepositReservedTime  Time of the last reserved deposit
    function getDepositReservationIsValid(address _from, uint256 _value, string _durationID, uint256 _rplRatio, uint256 _lastDepositReservedTime) public onlyNode(_from) onlyValidDuration(_durationID) returns(bool) { 
        // Get the settings
        rocketNodeSettings = RocketNodeSettingsInterface(getContractAddress("rocketNodeSettings"));
        // Check the ether deposit is ok - reverts if not
        getDepositEtherIsValid(_from, _value, _durationID);
        // Check the rpl deposit is ok  - reverts if not
        getDepositRPLIsValid(_from, _value, _durationID);
        // Check the node operator doesn't have a reservation that's current, must wait for that to expire first or cancel it.
        require(now > (_lastDepositReservedTime + rocketNodeSettings.getDepositReservationTime()), "Only one deposit reservation can be made at a time, the current deposit reservation will expire in under 24hrs.");
        // Check the rpl ratio is valid
        require(_rplRatio > 0, "RPL Ratio for deposit reservation cannot be less than or equal to zero.");
        require(_rplRatio < 3 ether, "RPL Ratio is too high.");
        // All ok
        return true;
    }


    /// @dev Checks if the deposit parameters are correct for a successful ether deposit
    /// @param _from  The address sending the deposit
    /// @param _value The amount being deposited
    /// @param _durationID The ID that determines which pool the user intends to join based on the staking blocks of that pool (3 months, 6 months etc)
    function getDepositEtherIsValid(address _from, uint256 _value, string _durationID) public onlyNode(_from) onlyValidDuration(_durationID) returns(bool) { 
        // Get the settings
        rocketNodeSettings = RocketNodeSettingsInterface(getContractAddress("rocketNodeSettings"));
        rocketMinipoolSettings = RocketMinipoolSettingsInterface(getContractAddress("rocketMinipoolSettings"));
        // Deposits turned on? 
        require(rocketNodeSettings.getDepositAllowed(), "Deposits are currently disabled for nodes.");
        // Is the deposit multiples of half needed to be deposited (node owners must deposit as much as we assign them)
        require(_value % (rocketMinipoolSettings.getMinipoolLaunchAmount().div(2)) == 0, "Ether deposit size must be multiples of half required for a deposit with Casper eg 16, 32, 64 ether.");
        // Check to verify the supplied mini pool staking time id is legit, it will revert if not
        rocketMinipoolSettings.getMinipoolStakingDuration(_durationID);
        // Check addresses are correct
        require(address(_from) != address(0x0), "From address is not a correct address");
        // All good
        return true;
    }


    /// @dev Checks if the deposit parameters are correct for a successful RPL deposit
    /// @param _from  The address sending the deposit
    /// @param _value The amount being deposited
    /// @param _durationID The ID that determines which pool the user intends to join based on the staking blocks of that pool (3 months, 6 months etc)
    function getDepositRPLIsValid(address _from, uint256 _value, string _durationID) public onlyNode(_from) onlyValidDuration(_durationID) returns(bool) { 
        // Get the settings
        rocketNodeSettings = RocketNodeSettingsInterface(getContractAddress("rocketNodeSettings"));
        rocketMinipoolSettings = RocketMinipoolSettingsInterface(getContractAddress("rocketMinipoolSettings"));
        // TODO: Check owner has sufficient RPL to cover the required amount
        // All good
        return true;
    }


    /*** Setters *************/


    /// @dev Returns the timezone of the node as Country/City eg America/New_York
    /// @param _timezoneLocation The location of the nodes timezone as Country/City eg America/New_York
    function setTimezoneLocation(string _timezoneLocation) public onlyNode(msg.sender) returns (string) {
        rocketStorage.setString(keccak256(abi.encodePacked("node.timezone.location", msg.sender)), _timezoneLocation);
    }
 

    /*** Methods *************/

    /// @dev Register a new node address if it doesn't exist
    /// @param _timezoneLocation The location of the nodes timezone as Country/City eg America/New_York
    function add(string _timezoneLocation) public onlyLatestContract("rocketNodeAPI", address(this)) returns (bool) {
        // Get the group settings
        rocketNodeSettings = RocketNodeSettingsInterface(getContractAddress("rocketNodeSettings"));
        // Initial address check
        require(address(msg.sender) != address(0x0), "An error has occurred with the sending address.");
        // Check the timezone location exists
        require(bytes(_timezoneLocation).length >= 4, "Node timezone supplied is invalid.");
        // Check registrations are allowed
        require(rocketNodeSettings.getNewAllowed() == true, "Group registrations are currently disabled in Rocket Pool");
        // Get the balance of the node, must meet the min requirements to service gas costs for checkins etc
        require(msg.sender.balance >= rocketNodeSettings.getEtherMin());
        // Check it isn't already registered
        require(!rocketStorage.getBool(keccak256(abi.encodePacked("node.exists", msg.sender))), "Node address already exists in the Rocket Pool network.");
        // Ok create the nodes contract now, this is the address where their ether/rpl deposits will reside
        RocketNodeContract newContractAddress = new RocketNodeContract(address(rocketStorage), msg.sender);
        // Get how many nodes we currently have  
        uint256 nodeCountTotal = rocketStorage.getUint(keccak256("nodes.total")); 
        // Ok now set our node data to key/value pair storage
        rocketStorage.setAddress(keccak256(abi.encodePacked("node.contract", msg.sender)), newContractAddress);
        rocketStorage.setString(keccak256(abi.encodePacked("node.timezone.location", msg.sender)), _timezoneLocation);
        rocketStorage.setUint(keccak256(abi.encodePacked("node.averageLoad", msg.sender)), 0);
        rocketStorage.setUint(keccak256(abi.encodePacked("node.lastCheckin", msg.sender)), 0);
        rocketStorage.setBool(keccak256(abi.encodePacked("node.active", msg.sender)), true);
        rocketStorage.setBool(keccak256(abi.encodePacked("node.exists", msg.sender)), true);
        // We store our nodes in an key/value array, so set its index so we can use an array to find it if needed
        rocketStorage.setUint(keccak256(abi.encodePacked("node.index", msg.sender)), nodeCountTotal);
        // Update total nodes
        rocketStorage.setUint(keccak256(abi.encodePacked("nodes.total")), nodeCountTotal + 1);
        // We also index all our nodes so we can do a reverse lookup based on its array index
        rocketStorage.setAddress(keccak256(abi.encodePacked("nodes.index.reverse", nodeCountTotal)), msg.sender);
        // Log it
        emit NodeAdd(msg.sender, newContractAddress, now);
        // Done
        return true;
    }

}