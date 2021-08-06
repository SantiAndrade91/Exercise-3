public class BeerAPICallout {

    @future(callout=true)
    // Asynchronous processing
    public static void makeGetCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer i = pageGenerator();
        String endPointURL = 'https://api.punkapi.com/v2/beers?per_page=30&page=';
        endPointURL = endPointURL + String.valueOf(i);
        System.debug(endPointURL);
        request.setEndpoint( endPointURL );
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            
            // List of Beers to insert into the database
            List<Beer__c> beersToInsert = new List<Beer__c>();
            
            // Deserializes the JSON string into collections of primitive data types.
            List<BeerAPI> result = (List<BeerAPI>)JSON.deserialize(response.getBody(), List<BeerAPI>.class);
			
            // Iterate over each beer retrieved from the API
            for (BeerAPI beer : result) {
            
                // Shorten the description to avoid longer strings (Limit = 150 characters).
                if (beer.description.length() > 100) {
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
        }        
	}
    
    private static void insertBeers( List<Beer__c> beerList ) {
        // Retrieve an existing list of beers (if any)
        List<Beer__c> oldBeerList = new List<Beer__c>();
        List<Beer__c> newBeerList = new List<Beer__c>();
            
        // If there were previous beers, the method checks for duplicates and updates the database accordingly
        for ( Beer__c beer : beerList ) {
            // Look for an existing beer, based on its ID
			Beer__c oldBeer = new Beer__c();

            Beer__c[] oldBeers = [SELECT External_ID__c, Name, Description__c, Tagline__c FROM Beer__c WHERE External_ID__c = :beer.External_ID__c];
            if ( oldBeers.size() > 0 ) oldBeer = oldBeers[0];

            if ( oldBeer.External_ID__c != null ) {
                oldBeerList.add(oldBeer);
            } else {
                newBeerList.add(beer);
            }
        }
        
        if (oldBeerList.size() > 0) update oldBeerList;
        if (newBeerList.size() > 0) insert newBeerList;
	}
    
    private static Integer pageGenerator() {
		Integer page = 0;
        Integer count = [SELECT count() FROM Beer__c];
        if ( count >= 30) page = (count / 30);
		page += 1;
        return page;
    }
}