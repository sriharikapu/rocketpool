pragma solidity 0.4.24;

// Contracts
import "./RocketBase.sol";
import "./contract/group/RocketGroupContract.sol";
// Interfaces
import "./interface/settings/RocketGroupSettingsInterface.sol";
// Utilities
import "./lib/Strings.sol";



/// @title A group is an entity that has users in the Rocket Pool infrastructure
/// @author David Rugendyke

contract RocketGroup is RocketBase {

    /*** Libs  **************/

    using Strings for string;


    /*** Contracts *************/

    RocketGroupSettingsInterface rocketGroupSettings = RocketGroupSettingsInterface(0);           // Settings for the groups
   


    /*** Events ****************/

     event GroupAdd (
        address ID,
        string name,
        uint256 stakingFee,
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
    
       
    /*** Constructor *************/

    /// @dev rocketGroup constructor
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
        // Version
        version = 1;
    }


    /*** Getters *************/

    /// @dev Get the group by its ID
    function getGroupName(address _ID) public view returns(string) { 
        // Get the group name
        rocketStorage.getString(keccak256(abi.encodePacked("group.name", _ID)));
    }

    /// @dev Get a verified address for the group that's allowed to interact with RP
    function getGroupAccessAddress(address _ID) public view returns(address) { 
        // Get the group name
        rocketStorage.getAddress(keccak256(abi.encodePacked("group.address", _ID)));
    }
    

    /*** Methods *************/

    /// @dev Register a new node address if it doesn't exist, only the contract creator can do this
    /// @param _name Name of the group (eg rocketpool, coinbase etc) - should be strictly lower case
    /// @param _stakingFee The fee this groups charges their users given as a % of 1 Ether (eg 0.02 ether = 2%)
    function add(string _name, uint256 _stakingFee) public payable returns (bool) {
        // Get the group settings
        rocketGroupSettings = RocketGroupSettingsInterface(rocketStorage.getAddress(keccak256("contract.name", "rocketGroupSettings")));
         // Make the name lower case
        _name = _name.lower();
        // Check the name is ok
        require(bytes(_name).length > 2, "Group Name is to short, must be a minimum of 3 characters.");
        // Check the staking fee is ok
        require(_stakingFee >= 0, "Staking fee cannot be less than 0.");
        // If there is a fee required to register a group, check that it is sufficient
        require(rocketGroupSettings.getNewFee() == msg.value, "New group fee insufficient.");
        // Check the group name isn't already being used
        require(bytes(rocketStorage.getString(keccak256(abi.encodePacked("group.name", _name)))).length == 0, "Group name is already being used.");
        // Ok create the groups contract now, this is where the groups fees and more will reside
        RocketGroupContract newContractAddress = new RocketGroupContract(address(rocketStorage));
        // Add the group to storage now
        uint256 groupCountTotal = rocketStorage.getUint(keccak256("groups.total")); 
        // Ok now set our data to key/value pair storage
        rocketStorage.setAddress(keccak256(abi.encodePacked("group.id", newContractAddress)), newContractAddress);
        rocketStorage.setString(keccak256(abi.encodePacked("group.name", newContractAddress)), _name);
        rocketStorage.setUint(keccak256("group.fee", newContractAddress), rocketGroupSettings.getDefaultFee());
        // We store our data in an key/value array, so set its index so we can use an array to find it if needed
        rocketStorage.setUint(keccak256(abi.encodePacked("group.index", newContractAddress)), groupCountTotal);
        // Update total partners
        rocketStorage.setUint(keccak256(abi.encodePacked("groups.total")), groupCountTotal + 1);
        // We also index all our groups so we can do a reverse lookup based on its array index
        rocketStorage.setAddress(keccak256(abi.encodePacked("groups.index.reverse", groupCountTotal)), newContractAddress);
        // Set the name as being used now
        rocketStorage.setString(keccak256(abi.encodePacked("group.name", _name)), _name);
        // Log it
        emit GroupAdd(newContractAddress, _name, _stakingFee, now);
    }

}