@isTest
private class BeerAPICalloutTest {
    
    @testSetup
    static void setup() {
        // Create and insert a Beer__c item
        Beer__c testBeer = new Beer__c();
        testBeer.External_ID__c = 1;
        testBeer.Name = 'Buzz';
        
        insert testBeer;
    }
    
    @isTest 
    static  void testGetCallout() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetBeerResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Call method to test
		Test.startTest();
        BeerAPICallout.makeGetCallout();        
        Test.stopTest();
        
        // Check results
        List<Beer__c> results = [SELECT Name FROM Beer__c];
		System.assertEquals(2, results.size(), 'The array should only contain 2 items.');
        System.assertEquals('Buzz', results[0].Name, 'The name of the beer does not match.');

    }   
}