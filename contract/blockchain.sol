// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Filecoin Decentralized Storage Contract
 * @dev A smart contract simulating decentralized file storage marketplace
 */
contract Project {
    
    struct StorageProvider {
        address providerAddress;
        uint256 availableStorage; // in GB
        uint256 pricePerGB; // in wei per GB per day
        uint256 reputation;
        bool isActive;
    }
    
    struct StorageDeal {
        uint256 dealId;
        address client;
        address provider;
        uint256 storageSize; // in GB
        uint256 duration; // in days
        uint256 totalCost;
        uint256 startTime;
        bool isActive;
    }
    
    mapping(address => StorageProvider) public storageProviders;
    mapping(uint256 => StorageDeal) public storageDeals;
    
    uint256 public dealCounter;
    address[] public providersList;
    
    event ProviderRegistered(address indexed provider, uint256 availableStorage, uint256 pricePerGB);
    event StorageDealCreated(uint256 indexed dealId, address indexed client, address indexed provider, uint256 storageSize, uint256 duration);
    event StorageDealCompleted(uint256 indexed dealId, address indexed provider);
    
    /**
     * @dev Register as a storage provider
     * @param _availableStorage Amount of storage to offer in GB
     * @param _pricePerGB Price per GB per day in wei
     */
    function registerProvider(uint256 _availableStorage, uint256 _pricePerGB) external {
        require(_availableStorage > 0, "Storage must be greater than 0");
        require(_pricePerGB > 0, "Price must be greater than 0");
        require(!storageProviders[msg.sender].isActive, "Provider already registered");
        
        storageProviders[msg.sender] = StorageProvider({
            providerAddress: msg.sender,
            availableStorage: _availableStorage,
            pricePerGB: _pricePerGB,
            reputation: 100,
            isActive: true
        });
        
        providersList.push(msg.sender);
        
        emit ProviderRegistered(msg.sender, _availableStorage, _pricePerGB);
    }
    
    /**
     * @dev Create a storage deal with a provider
     * @param _provider Address of the storage provider
     * @param _storageSize Size of storage needed in GB
     * @param _duration Duration of storage in days
     */
    function createStorageDeal(address _provider, uint256 _storageSize, uint256 _duration) external payable {
        require(storageProviders[_provider].isActive, "Provider not active");
        require(_storageSize > 0 && _duration > 0, "Invalid storage parameters");
        
        StorageProvider storage provider = storageProviders[_provider];
        require(provider.availableStorage >= _storageSize, "Insufficient storage available");
        
        uint256 totalCost = provider.pricePerGB * _storageSize * _duration;
        require(msg.value >= totalCost, "Insufficient payment");
        
        dealCounter++;
        storageDeals[dealCounter] = StorageDeal({
            dealId: dealCounter,
            client: msg.sender,
            provider: _provider,
            storageSize: _storageSize,
            duration: _duration,
            totalCost: totalCost,
            startTime: block.timestamp,
            isActive: true
        });
        
        provider.availableStorage -= _storageSize;
        
        // Transfer payment to provider
        payable(_provider).transfer(totalCost);
        
        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        emit StorageDealCreated(dealCounter, msg.sender, _provider, _storageSize, _duration);
    }
    
    /**
     * @dev Complete a storage deal and return storage to provider
     * @param _dealId ID of the storage deal
     */
    function completeStorageDeal(uint256 _dealId) external {
        StorageDeal storage deal = storageDeals[_dealId];
        require(deal.isActive, "Deal is not active");
        require(msg.sender == deal.provider, "Only provider can complete deal");
        require(block.timestamp >= deal.startTime + (deal.duration * 1 days), "Deal duration not finished");
        
        deal.isActive = false;
        storageProviders[deal.provider].availableStorage += deal.storageSize;
        storageProviders[deal.provider].reputation += 10; // Increase reputation
        
        emit StorageDealCompleted(_dealId, deal.provider);
    }
    
    /**
     * @dev Get list of all active providers
     */
    function getActiveProviders() external view returns (address[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < providersList.length; i++) {
            if (storageProviders[providersList[i]].isActive) {
                activeCount++;
            }
        }
        
        address[] memory activeProviders = new address[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < providersList.length; i++) {
            if (storageProviders[providersList[i]].isActive) {
                activeProviders[index] = providersList[i];
                index++;
            }
        }
        
        return activeProviders;
    }
}
