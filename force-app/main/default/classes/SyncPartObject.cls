public class SyncPartObject {

    // Method to initiate the synchronization process
    public static void syncPartRecords() {
        String profileID = UserInfo.getProfileId();
        List<Profile> profileName = [SELECT Name FROM Profile WHERE Id = :profileID];
        List<PermissionSetAssignment> assignments = [SELECT Id, PermissionSetId
                                                     FROM PermissionSetAssignment
                                                     WHERE AssigneeId = :UserInfo.getUserId()];
        
        if ((profileName.isEmpty() || !profileName[0].Name.equals('System Administrator')) && assignments[0].Id != '2F0PSGA000003qBnA' ) {
            throw new AuraHandledException('You do not have access.');
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://cqparts-3d06.restdb.io/rest/cqpart');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-api-key', 'b96d75ce0f9f342d10af6710ef8ea7ed0ad06');
 
        Http http = new Http();
        HttpResponse res = http.send(req);
 
        System.debug('Response: ' + res);  
       
        if (res.getStatusCode() == 200) {
            String responseBody = res.getBody();
            System.debug('Response Body: ' + responseBody);
            if (String.isNotBlank(responseBody)) {
            try {
                List<Object> parts = (List<Object>) JSON.deserializeUntyped(responseBody);
                System.debug('Deserialized Parts: ' + parts);
                
                List<SQX_Part__c> partRecords = new List<SQX_Part__c>();
                List<Account> highVolumeAccounts = [SELECT Id FROM Account WHERE Name = 'High Volume' LIMIT 1];
                List<Account> lowVolumeAccounts = [SELECT Id FROM Account WHERE Name = 'Low Volume' LIMIT 1];

                for (Object part : parts) {
    try {
        Map<String, Object> partMap = (Map<String, Object>) part;
        
        
        
        System.debug('Part Map: ' + partMap);
        
           
        // Check for null values before accessing map keys
        if (partMap != null) {
            SQX_Part__c newPart = new SQX_Part__c();
            newPart.Part_Number__c = String.valueOf(partMap.get('_Id'));
            newPart.Name = String.valueOf(partMap.get('Part Name'));
            newPart.Active__c = true; // Hardcoded as 'true' as per the requirement
            if (partMap.get('Total_Quantity_Shipped') != null) {
                Integer totalQuantityShipped = Integer.valueOf(String.valueOf(partMap.get('Total_Quantity_Shipped')));
                system.debug('totalQuantityShipped' + totalQuantityShipped);
                newPart.Related_Account__c = totalQuantityShipped>99 ? highVolumeAccounts[0].id: lowVolumeAccounts[0].id;
            }
            partRecords.add(newPart);
        } else {
            System.debug('Part Map is null');
        }
    } catch (Exception e) {
        System.debug('Error processing part: ' + e.getMessage());
    }
}
                // Insert the new Part records
                if (!partRecords.isEmpty()) {
                    insert partRecords;
                    System.debug('Part Records Inserted: ' + partRecords);
                }
            } catch (Exception e) {
                System.debug('Error deserializing JSON: ' + e.getMessage());
                throw new AuraHandledException('Error deserializing JSON: ' + e.getMessage());
            }
        } else {
            System.debug('Non-200 status code received: ' + res.getStatusCode());
        }
    }
 }


}
