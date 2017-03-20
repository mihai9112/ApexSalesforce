public with sharing class CommercialSchedulerControllerExtension
{
    public Commercial__c commercial {get; set;}
    public String selectedProgramGenre {get; set;}
    public List<ViewModel> Model {get; set;}
    private CommercialSchedulerBuilder builder;

    public CommercialSchedulerControllerExtension(ApexPages.StandardController stdController)
    {
        Commercial__c returnedCommercial = (Commercial__c)stdController.getRecord();
        if (returnedCommercial.Id == null)
        {
            Id accountId = GetIdFromQueryString();
            commercial = new Commercial__c(
                Broadcast_Start_Date__c = Date.today(),
                Broadcast_Stop_Date__c = Date.today().addDays(14),
                Account__c = accountId
            );
        }
        else
        {
            commercial = [Select Id, 
                                 Name, 
                                 Running_Time_Seconds__c, Account__c, 
                                 Broadcast_Start_Date__c, 
                                 Total_Broadcast_Time_Seconds__c, 
                                 Broadcast_Stop_Date__c, 
                                 Contracted_Broadcast_Time_Seconds__c 
                          From Commercial__c 
                          Where Id = : returnedCommercial.Id];
        }

        builder = new CommercialSchedulerBuilder();
        Model = builder
                .GetTimeSlots(commercial)
                .Build();
    }

    public void Filter()
    {
        builder = new CommercialSchedulerBuilder();
        Model = builder
                 .GetTimeSlots(commercial, selectedProgramGenre)
                 .Build();
    }

    private Id GetIdFromQueryString()
    {
        String unTrimmedParameter = ApexPages.currentPage().getParameters().get('retUrl');
        if (unTrimmedParameter != null && (unTrimmedParameter.length() == 16 || unTrimmedParameter.length() == 19))
        {
            return unTrimmedParameter.substring(1, unTrimmedParameter.length());
        }
        return null;
    }

    public List<SelectOption> GetProgramGenre()
    {
        List<SelectOption> programGenre = new List<SelectOption>();
        programGenre.add(new SelectOption('All', 'All'));
        Schema.DescribeFieldResult picklist = Timeslot__c.Program_Genre__c.getDescribe();
        List<Schema.PicklistEntry> entries = picklist.getPicklistValues();

        for(Schema.PicklistEntry entry : entries)
        {
            programGenre.add(new SelectOption(entry.getLabel(), entry.getValue()));
        }

        return programGenre;
    }
}