// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract OracleSync {
    // Struct to store oracle data
    struct OracleData {
        uint256 value;
        uint256 timestamp;
        address provider;
        bool isActive;
    }
    
    // Mapping to store data feeds by key
    mapping(string => OracleData) public dataFeeds;
    
    // Mapping to track authorized data providers
    mapping(address => bool) public authorizedProviders;
    
    // Contract owner
    address public owner;
    
    // Events
    event DataUpdated(string indexed key, uint256 value, address indexed provider, uint256 timestamp);
    event ProviderAuthorized(address indexed provider);
    event ProviderRevoked(address indexed provider);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedProvider() {
        require(authorizedProviders[msg.sender], "Only authorized providers can update data");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        authorizedProviders[msg.sender] = true;
    }
    
    /**
     * Core Function 1: Update Data Feed
     * Allows authorized providers to submit/update oracle data
     */
    function updateDataFeed(string memory _key, uint256 _value) external onlyAuthorizedProvider {
        require(bytes(_key).length > 0, "Key cannot be empty");
        
        dataFeeds[_key] = OracleData({
            value: _value,
            timestamp: block.timestamp,
            provider: msg.sender,
            isActive: true
        });
        
        emit DataUpdated(_key, _value, msg.sender, block.timestamp);
    }
    
    /**
     * Core Function 2: Get Data Feed
     * Allows anyone to query oracle data
     */
    function getDataFeed(string memory _key) external view returns (
        uint256 value,
        uint256 timestamp,
        address provider,
        bool isActive
    ) {
        require(bytes(_key).length > 0, "Key cannot be empty");
        require(dataFeeds[_key].isActive, "Data feed is not active");
        
        OracleData memory data = dataFeeds[_key];
        return (data.value, data.timestamp, data.provider, data.isActive);
    }
    
    /**
     * Core Function 3: Manage Data Providers
     * Allows owner to authorize or revoke data providers
     */
    function manageProvider(address _provider, bool _authorized) external onlyOwner {
        require(_provider != address(0), "Invalid provider address");
        
        authorizedProviders[_provider] = _authorized;
        
        if (_authorized) {
            emit ProviderAuthorized(_provider);
        } else {
            emit ProviderRevoked(_provider);
        }
    }
    
    /**
     * Additional utility function to check if data exists and is fresh
     */
    function isDataFresh(string memory _key, uint256 _maxAge) external view returns (bool) {
        if (!dataFeeds[_key].isActive) {
            return false;
        }
        
        return (block.timestamp - dataFeeds[_key].timestamp) <= _maxAge;
    }
    
    /**
     * Get multiple data feeds at once for efficiency
     */
    function getMultipleDataFeeds(string[] memory _keys) external view returns (
        uint256[] memory values,
        uint256[] memory timestamps,
        address[] memory providers
    ) {
        uint256 length = _keys.length;
        values = new uint256[](length);
        timestamps = new uint256[](length);
        providers = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            if (dataFeeds[_keys[i]].isActive) {
                values[i] = dataFeeds[_keys[i]].value;
                timestamps[i] = dataFeeds[_keys[i]].timestamp;
                providers[i] = dataFeeds[_keys[i]].provider;
            }
        }
        
        return (values, timestamps, providers);
    }
}
