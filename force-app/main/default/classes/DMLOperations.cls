/**
 * The DMLOperations class serves as a deep dive into Data Manipulation Language (DML) in Apex.
 * It covers fundamental DML operations such as insert, update, upsert, and delete.
 *
 * This class introduces developers to the concept of manipulating Salesforce records in Apex.
 * It discusses how to use DML operations to create, update, and delete records.
 * This class uses standard Salesforce objects like Account, Contact, and Opportunity for demonstration.
 *
 * Topics covered in this class include:
 * - Understanding how to use insert DML operation to create records in Salesforce.
 * - Understanding how to use update and upsert DML operations to update existing records in Salesforce.
 * - Understanding how to use delete DML operation to remove records from Salesforce.
 *
 * Users of this class can expect to gain a strong understanding of DML operations in Apex and
 * be prepared for more advanced topics in Salesforce development.
 *
 * The methods within this class serve as practical examples of different DML operations,
 * allowing developers to learn through practice and examples.
 *
 * @author Rebekah Callant
 */


public with sharing class DMLOperations {

    /**
     * Question 1
     * Create a new Account object and inserts it into the database.
     * The Account will have a random name for uniqueness.
     * @ return The Id of the newly created Account.
     */
    public static Id insertNewAccount() {
       String randomName = 'Account_' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        
        Account newAccount = new Account(Name = randomName);
 
        insert newAccount;
       
        return newAccount.Id;
    }
    

    /**
     * Question 2
     * Create a new Account with the specified name and industry provided.
     * @ param name The name of the account to be created.
     * @ param industry The industry of the account to be created.
     */
    public static void createAccount(String name, String industry) {
        // Create a new Account and set the fields inline
        Account acc = new Account (Name = name, Industry = industry);
        
        // Insert the Account
        insert acc;
    }

    
    /**
     * Question 3
     * Create a new Contact and link it to the Account id provided then inserts it into the database.
     * @ param accountId The Id of the Account to link the Contact to.
     * @ return The Id of the newly created Contact.
     */
    public static Id insertNewContact(Id accountId) {
        List<Account> firstAccount = [SELECT Id FROM Account LIMIT 1];
        accountId = firstAccount[0].Id;
   
        Contact newContact = new Contact(FirstName = 'Becky', LastName = 'Hiltman');
        newContact.AccountId = accountId;
        newContact.Email = 'becky@noemail.com';
       
        insert newContact;
    
        return newContact.Id;
    
    }

    /**
     * Question 4
     * Update the last name of a Contact in the database.
     * Resource: https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql.htm
     * @param contactId The Id of the Contact to update.
     * @param newLastName The new last name for the Contact.
     */
    public static void updateContactLastName(Id contactId, String newLastName) {
        
        Contact fetchContact = [SELECT Id, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
        
        fetchContact.LastName = newLastName;
        
        	update fetchContact;
        }
     

    /**
     * Question 5
     * Update the stage of an Opportunity in the database.
     * Resource: https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql.htm
     * @param oppId The Id of the Opportunity to update.
     * @param newStage The new stage for the Opportunity.
     */
    public static void updateOpportunityStage(Id oppId, String newStage) {
        Opportunity fetchOpp = [SELECT Id, StageName, AccountId, Name, CloseDate FROM Opportunity WHERE Id = :oppId];
        
        fetchOpp.StageName = newStage;
        update fetchOpp;
            
        }
        

    /**
     * Question 6
     * Update the Account's Name and Industry given an Account Id.
     * Resource: https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql.htm
     * @param accountId The Id of the account to be updated.
     * @param newName The new name for the account.
     * @param newIndustry The new industry for the account.
     */
    public static void updateAccountFields(Id accountId, String newName, String newIndustry) {
        Account fetchAcct = [SELECT Id, Name, Industry FROM Account LIMIT 1];
        
        fetchAcct.Name = newName;
        fetchAcct.Industry = newIndustry;
        update fetchAcct;
    }


    /**
     * Question 7
     * Create or updates an Opportunities
     * The Opportunity's Stage is set to Qualification.
     * The Opportunity's Close Date is set to 3 months from today.
     * The Opportunity's Amount is set to 50000.
     * @param list of Opportunities to be changed then upserted.
     */
    public static void upsertOpportunityList(List<Opportunity> opportunities) {

        for (Opportunity opp : opportunities) {
        opp.StageName = 'Qualification';
        opp.CloseDate = Date.today().addMonths(3);
        opp.Amount = 50000;
    }
    
    upsert opportunities;
}

    /**
     * Question 8
     * Insert or update opportunities from list of names.
     * Associate the Opportunities with account that has the name accountName.
     * There should be an Opportunity for each name provided in the list.
     * HINT: The account may or may not exists in the database but is required for opportunity creation. Consider how upsert operation can help with this.
     * HINT: There should not be duplicate opportunites based on the name
     * @param accountName The name of the Account.
     * @param oppNames The list of Opportunity names.
     */

public static void upsertOpportunities(String accountName, List<String> oppNames) {
    // Guard clauses
    if (String.isBlank(accountName) || oppNames == null || oppNames.isEmpty()) {
        return;
    }

    // Ensure the Account exists (query or insert once)
    Account acct;
    List<Account> existingAccts = [SELECT Id, Name FROM Account WHERE Name = :accountName LIMIT 1];
    if (existingAccts.isEmpty()) {
        acct = new Account(Name = accountName);
        insert acct;
    } else {
        acct = existingAccts[0];
    }

    // Clean & de-duplicate the incoming names
    Set<String> targetNames = new Set<String>();
    for (String n : oppNames) {
        if (!String.isBlank(n)) targetNames.add(n.trim());
    }
    if (targetNames.isEmpty()) return;

    // Fetch existing Opportunities for this Account that match those names
    Map<String, Opportunity> existingByName = new Map<String, Opportunity>();
    for (Opportunity o : [
        SELECT Id, Name
        FROM Opportunity
        WHERE AccountId = :acct.Id AND Name IN :targetNames
    ]) {
        existingByName.put(o.Name, o);
    }

    // Build list to upsert (update existing, insert missing)
    List<Opportunity> toUpsert = new List<Opportunity>();
    // Salesforce requires StageName and CloseDate when inserting an Opportunity.
    Date defaultClose = Date.today().addMonths(3);

    for (String name : targetNames) {
        if (existingByName.containsKey(name)) {
            // Update the existing record (no-op fields here, but keeps it idempotent)
            toUpsert.add(new Opportunity(
                Id        = existingByName.get(name).Id,
                Name      = name,
                AccountId = acct.Id
            ));
        } else {
            // Insert a new record with required fields
            toUpsert.add(new Opportunity(
                Name      = name,
                AccountId = acct.Id,
                StageName = 'Prospecting',
                CloseDate = defaultClose
            ));
        }
    }

    // Single DML (bulk-safe)
    upsert toUpsert;
}


    /**
     * Question 9
	 * Upserts an Account with the specified name.
	 * If an Account with the given name already exists, update the description to "Updated Account".
	 * If no such Account exists, it creates a new one and sets the description to "New Account".
	 * @param accountName The name of the Account to be upserted.
	 * @return The Account that was upserted.
	 */
    public static Account upsertAccount(String accountName) {
    if (String.isBlank(accountName)) {
        throw new IllegalArgumentException('accountName is required');
    }

    // Query into a LIST to avoid QueryException when nothing matches
    List<Account> matches = [
        SELECT Id, Name, Description
        FROM Account
        WHERE Name = :accountName
        LIMIT 1
    ];

    Account acc;
    if (!matches.isEmpty()) {
        acc = matches[0];
        acc.Description = 'Updated Account';
    } else {
        acc = new Account(Name = accountName, Description = 'New Account');
    }

    // Upsert uses UPDATE when Id is set, INSERT otherwise
    upsert acc;
    return acc;
}



    /**
     * Question 10
	 * Manage the association between Contacts and Accounts
	 * Ensure that for each Contact in the provided list, there is a corresponding Account Name that matches the Contact's last name.
	 * If such an Account does not exist, the method creates it; if it does, the method ensures the Contact is associated with it. (Hint: use previous upsertAccount method - this may cause bad practices but for learning purposes it's okay.)
     * Example Contact.LastName = 'Doe' Link to Account.Name = 'Doe' 
     * Example Contact.LastName = 'Jane' Link to Account.Name = 'Jane'
	 * @param contactsToUpsert List of Contacts to be upserted and linked to accounts.
	 */
	public static void upsertAccountsWithContacts(List<Contact> contactsToUpsert) {
    if (contactsToUpsert == null || contactsToUpsert.isEmpty()) return;

    // 1) Gather target Account names (Contact.LastName)
    Set<String> acctNames = new Set<String>();
    for (Contact c : contactsToUpsert) {
        if (!String.isBlank(c.LastName)) {
            acctNames.add(c.LastName.trim());
        }
    }
    if (acctNames.isEmpty()) {
        // No valid last names; just upsert contacts as-is (or throw if you prefer)
        upsert contactsToUpsert;
        return;
    }

    // 2) Fetch existing Accounts by Name
    Map<String, Account> acctByName = new Map<String, Account>();
    for (Account a : [SELECT Id, Name FROM Account WHERE Name IN :acctNames]) {
        acctByName.put(a.Name, a);
    }

    // 3) Insert missing Accounts
    List<Account> toInsert = new List<Account>();
    for (String name : acctNames) {
        if (!acctByName.containsKey(name)) {
            toInsert.add(new Account(Name = name, Description = 'New Account')); // optional Description
        }
    }
    if (!toInsert.isEmpty()) {
        insert toInsert;
        for (Account a : toInsert) {
            acctByName.put(a.Name, a);
        }
    }

    // 4) Link Contacts to their Account by last name
    for (Contact c : contactsToUpsert) {
        if (!String.isBlank(c.LastName)) {
            Account a = acctByName.get(c.LastName.trim());
            if (a != null) c.AccountId = a.Id;
        }
    }

    // 5) Upsert contacts once
    upsert contactsToUpsert;
}

    /**
     * Question 11
     * Insert a list of Leads and then deletes them.
     * @param leadNames The list of Lead names to be inserted.
     */
    public static void insertAndDeleteLeads(List<String> leadNames) {
        // Loop through each Lead name
            Lead newLead = new Lead(LastName = 'Lead', Company = 'Guess Alot');
            insert newLead;
            delete newLead;
            
        }
        //  Do i need a list and then delete the list?


    /**
     * Question 12
     * Dynamically create the number of cases and relate it to the accountId, then deletes them.
     * @param accountId The account for which the cases will be created and then deleted.
     * @param numOfCases The number of cases to create.
     */
    public static void createAndDeleteCases(String accountId, Integer numOfCases) {
        // Insert the cases
        List <Case> caseList = new List <Case>();
        for (Integer i = 0; i < numOfCases; i++) {
            Case newCase = new Case(Subject = 'Case ' + String.valueOf(i), AccountId= accountId);
            caseList.add(newCase);
   
    }
     insert caseList;
     delete caseList;
}
}