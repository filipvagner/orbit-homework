targetScope = 'subscription'

module modTfStateRg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'modTfStateRg'
  params: {
    name: 'rg-orbittfstate-tst-use2-001'
    location: deployment().location
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.13.2' = {
  scope: resourceGroup('rg-orbittfstate-tst-use2-001') // If referenced by a module name, then is not listed in change output
  name: 'storageAccountDeployment'
  dependsOn: [
    modTfStateRg
  ]
  params: {
    name: 'storbittfstate001'
    location: deployment().location
    skuName: 'Standard_LRS'
    tags: {
      Application: 'Storage for Terraform State'
      Importance: 'High'
      Environment: 'Test'
    }
    allowBlobPublicAccess: true
    blobServices: {
      automaticSnapshotPolicyEnabled: true
      deleteRetentionPolicyDays: 9
      deleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: 10
      containerDeleteRetentionPolicyEnabled: true
      isVersioningEnabled: true
      lastAccessTimeTrackingPolicyEnabled: false
      containers: [
        {
          name: 'orbit-tfstate'
          publicAccess: 'None'
        }
      ]

    }
  }
}
