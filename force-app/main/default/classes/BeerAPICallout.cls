public with sharing class BeerAPICallout {
	
    // PUNK API end point URL 
    private static final String END_POINT_URL = 'https://api.punkapi.com/v2/beers?per_page=30&page=';
    
    @future(callout=true)
    // Asynchronous processing
    public static void makeGetCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Obtain different beers on each request made
        Integer i = pageGenerator();
        String endPointURL = END_POINT_URL + String.valueOf(i);
        System.debug(endPointURL);
        
        // Request the beers
        request.setEndpoint( endPointURL );
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
        // If the request is successful, parse the JSON response.

            // List of Beers to insert into the database
            List<Beer__c> beersToInsert = new List<Beer__c>();
            
            // Deserializes the JSON string into collections of primitive data types.
            List<BeerAPI> result = (List<BeerAPI>)JSON.deserialize(response.getBody(), List<BeerAPI>.class);
			
            // Iterate over each beer retrieved from the API
            for (BeerAPI beer : result) {
                // Shorten the description to avoid longer strings (Limit = 150 characters).
                if (beer.description.length() > 150) {
                    beer.description = beer.description.abbreviate(150);
                }
                // System.debug(beer);
                // Create a new Beer__c object and add it to the list to insert
                Beer__c newBeer = new Beer__c();
                newBeer.Name = beer.name;
                newBeer.Description__c = beer.description;
                newBeer.External_ID__c = beer.id;
                newBeer.Tagline__c = beer.tagline;
                
                beersToInsert.add(newBeer);
            }
            
            // Call the method to insert beers without duplicating them
            if (beersToInsert.size() > 0) {
                insertBeers( beersToInsert );
                System.debug('The list of beers from PUNK API was successfully upserted! Total: ' + beersToInsert.size());
            }
        
        } else if (response.getStatusCode() == 400) {
            
            // If the request fails, a message is shown in the console.
            System.debug('Error: Bad Request. A parameter in the request was passed without a value!');
        
        } else if (response.getStatusCode() == 404) {
            
            // Page not found
            System.debug('Error: Not Found. The server can not find the requested resource.');
        
        } else if (response.getStatusCode() > 500) {
            
            // Server errors
            System.debug('Server Error.');
        }
        
        
	}
    
    // Method to insert new beers to the database
    private static void insertBeers( List<Beer__c> beerList ) {

        List<Beer__c> oldBeerList = new List<Beer__c>();
        List<Beer__c> newBeerList = new List<Beer__c>();

        // CRUD Validation
        if (Beer__c.SObjectType.getDescribe().isAccessible() 
            && Schema.SObjectType.Beer__c.fields.External_ID__c.isAccessible()
           ) {
        	// Retrieve an existing list of beers
            oldBeerList = [SELECT External_ID__c FROM Beer__c WITH SECURITY_ENFORCED];
        }
          
        for ( Beer__c beer : beerList ) {
            if ( !oldBeerList.contains(beer) ) { newBeerList.add(beer); }
        }
        
        // Make sure there are elements in the list to be inserted and CRUD validation
        if ( newBeerList.size() > 0 
             && Beer__c.SObjectType.getDescribe().isCreateable()
        	) { 
            insert newBeerList;
        }

	}
    
    // Method to generate a new page for the URL in the API call
    private static Integer pageGenerator() {
		Integer page = 0;
        Integer count = [SELECT count() FROM Beer__c];
        if ( count >= 30) { page = (count / 30); }
		page += 1;
        return page;
    }
}