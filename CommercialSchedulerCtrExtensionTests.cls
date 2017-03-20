@isTest
private class CommercialSchedulerCtrExtensionTests extends BaseTest
{
	private static final Integer allowedCommercialTime = 30;
	private static final Integer randomNumberOfBroadcasts = 2;
	private static final String randomCommercialName = 'klhiads';
	private static final String randomAccountName = 'iuihadaw';
	private static final String randomProgramName = 'oijdoaiwu';

	@testSetup static void setup()
	{
		List<SObject> objectsToInsert = new List<SObject>();
		Account randomAccount = t.CreateSingleAccount(randomAccountName);
		objectsToInsert.add(randomAccount);
		Commercial__c randomCommercial = t.CreateSingleCommercial(randomCommercialName, randomAccount);
		objectsToInsert.add(randomCommercial);
		Timeslot__c randomTimeSlot = t.CreatingSingleTimeSlot(randomProgramName, allowedCommercialTime);
		randomTimeSlot.Timeslot_Date_Time__c = Date.today().addDays(2);
		objectsToInsert.add(randomTimeSlot);
		insert objectsToInsert;
	}

	@isTest static void CommercialSchedulerControllerExtension_OneExistingCommercial_PopulateCommercialOnExtension()
	{
		System.runAs(t.admin)
		{
			Commercial__c commercial = [Select Id, 
											   Name, 
											   Running_Time_Seconds__c, 
											   Account__c, 
											   Broadcast_Start_Date__c, 
											   Total_Broadcast_Time_Seconds__c, 
											   Broadcast_Stop_Date__c,
											   Contracted_Broadcast_Time_Seconds__c 
										From Commercial__c];
			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(commercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			Date expectedStopDate = Date.today().addDays(14);
			System.assertEquals(randomCommercialName, extension.commercial.Name, 'Name is populated on extension');
			System.assertEquals(expectedStopDate, extension.commercial.Broadcast_Stop_Date__c, 'Broadcast stop date should default to 14 after the start date');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialToCreate_DisplayPageWithoutPopulatedFields()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			Date expectedStopDate = Date.today().addDays(14);
			System.assert(extension.commercial.Name == null, 'Name should be null for a new commercial');
			System.assertEquals(expectedStopDate, extension.commercial.Broadcast_Stop_Date__c, 'Broadcast stop date should default to 14 after the start date');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_CreateNewCommercialFromAccountRelatedList_PrePopulateAccount()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.currentPage().getParameters().put('retUrl', '/'+account.Id);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			System.assertEquals(account.Id, extension.commercial.Account__c, 'Account is populated when you create a new commercial from account related list');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialWithOneTimeslotAvailable_PopulateTheViewModelWithTimeSlots()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			final Integer expectedNumberOfBroadcasts = 0;
			System.assert(!extension.Model.isEmpty(), 'ViewModel should be populated with the timeslots');
			System.assertEquals(expectedNumberOfBroadcasts, extension.Model[0].GetNumberOfBroadcast(), 'When there is no commercial slots, display zero');
		}		
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialWithOneTimeSlotThatIsLinkedToACommercialSlot_PopulateTheViewModelWithTheTimeSlotAndTheNumberOfBroadcastOfTheCommercialSlot()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Timeslot__c timeSlot = [Select Id From Timeslot__c];
			Commercial_slot__c commercialSlot = t.CreateSingleCommercialSlot(randomNumberOfBroadcasts);
			commercialSlot.Timeslot__c = timeSlot.Id;
			insert commercialSlot;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			final Decimal expectedNumberOfBroadcastsForANewCommercial = 0;
			System.assertEquals(expectedNumberOfBroadcastsForANewCommercial, extension.Model[0].GetNumberOfBroadcast(), 'Populate ViewModel with 0 because the commercial slots are not linked to the commercial');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialWithOneTimeSlotThatIsLinkedToTwoCommercialSlots_PopulateTheViewModelWithTheTimeSlotAndTheNumberOfBroadcastOfTheCommercialSlots()
	{
		System.runAs(t.admin)
		{
			List<Commercial_slot__c> commercialSlots = new List<Commercial_slot__c>();
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Timeslot__c timeSlot = [Select Id From Timeslot__c];
			Commercial_slot__c commercialSlot = t.CreateSingleCommercialSlot(randomNumberOfBroadcasts);
			commercialSlot.Timeslot__c = timeSlot.Id;
			Commercial_slot__c secondCommercialSlot = t.CreateSingleCommercialSlot(randomNumberOfBroadcasts);
			secondCommercialSlot.Timeslot__c = timeSlot.Id;
			commercialSlots.add(commercialSlot);
			commercialSlots.add(secondCommercialSlot);
			insert commercialSlots;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			final Decimal expectedNumberOfBroadcastsForANewCommercial = 0;
			System.assertEquals(expectedNumberOfBroadcastsForANewCommercial, extension.Model[0].GetNumberOfBroadcast(), 'Populate ViewModel with 0 because the commercial slots are not linked to the commercial');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_ExistingCommercialWithACommercialSlotThatIsLinkedToATimeSlot_PopulateTheViewModelWithTheTimeSlotAndTheNumberOfBroadcastFromTheCommercialSlot()
	{
		System.runAs(t.admin)
		{
			Commercial__c commercial = [Select Id From Commercial__c];
			Timeslot__c timeSlot = [Select Id From Timeslot__c];
			Commercial_slot__c commercialSlot = t.CreateSingleCommercialSlot(randomNumberOfBroadcasts);
			commercialSlot.Commercial__c = commercial.Id;
			commercialSlot.Timeslot__c = timeSlot.Id;
			insert commercialSlot;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(commercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			System.assertEquals(commercialSlot.Number_of_Broadcasts__c, extension.Model[0].GetNumberOfBroadcast(), 'Populate ViewModel with the cummulative number of broadcasts from the commercial slots linked to the commercial');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialAndOneTimeSlotOutsideTheDateRange_ViewModelIsNotPopulated()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Timeslot__c timeSlot = [Select Id, Timeslot_Date_Time__c From Timeslot__c];
			timeSlot.Timeslot_Date_Time__c = Date.today().addDays(20);
			update timeSlot;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			System.assert(extension.Model.isEmpty(), 'ViewModel is not populated with timeslots out of range for a new commercial');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_OneExistingCommercialWithOneCommercialSlotAndOneTimeSlotLinkedButOutOfRange_ViewModelIsNotPopulated()
	{
		System.runAs(t.admin)
		{
			Commercial__c commercial = [Select Id From Commercial__c];
			Timeslot__c timeSlot = [Select Id, Timeslot_Date_Time__c From Timeslot__c];
			timeSlot.Timeslot_Date_Time__c = Date.today().addDays(20);
			update timeSlot;

			Commercial_slot__c commercialSlot = t.CreateSingleCommercialSlot(randomNumberOfBroadcasts);
			commercialSlot.Commercial__c = commercial.Id;
			insert commercialSlot;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(commercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			System.assert(extension.Model.isEmpty(), 'ViewModel is not populated with timeslots out of range for an existing commercial');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialWithTwoTimeSlotsAvailable_SortThemByTimeSlotDateTime()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);
			Timeslot__c secondTimeSlot = t.CreatingSingleTimeSlot(randomProgramName, allowedCommercialTime);
			secondTimeSlot.Timeslot_Date_Time__c = Date.today().addDays(3);
			insert secondTimeSlot;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			System.assert(extension.Model.size() == 2, 'ViewModel is populated with two available timeslots');
			System.assertEquals(extension.Model[1].GetTimeSlotId(), secondTimeSlot.Id, 'The second timeslot will be second because of the time slot date time sort');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_NewCommercialWithOneTimeSlotThatHas0LeftInTheRemainingCommercialTimeField_ViewModelIsNotPopulated()
	{
		System.runAs(t.admin)
		{
			final Integer oneBroadcast = 1;
			Account account = [Select Id From Account];
			Timeslot__c timeSlot = [Select Id From Timeslot__c];
			Commercial__c commercial = [Select Id From Commercial__c];
			Commercial_slot__c commercialSlot = t.CreateSingleCommercialSlot(oneBroadcast);
			commercialSlot.Timeslot__c = timeSlot.Id;
			commercialSlot.Commercial__c = commercial.Id;
			insert commercialSlot;

			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomCommercialName, account);

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);

			Test.startTest();
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			Test.stopTest();

			System.assert(extension.Model.isEmpty(), 'ViewModel is not populated with timeslots that have 0 seconds of remaining commercial time if the timeslot is not linked to the commercial');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_GetPicklistValues_PopulateSelectList()
	{
		System.runAs(t.admin)
		{
			List<SelectOption> programGenre = new List<SelectOption>();
			Commercial__c commercial = [Select Id From Commercial__c];
			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(commercial);
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);

			Test.startTest();
			programGenre = extension.GetProgramGenre();
			Test.stopTest();

			System.assert(!programGenre.isEmpty(), 'Populate list of select options from the values of the picklist');
		}
	}

	@isTest static void CommercialSchedulerControllerExtension_FilterTimeslotsByActionGenre_PopulateViewModelWithFilteredResults()
	{
		System.runAs(t.admin)
		{
			Account account = [Select Id From Account];
			Commercial__c notInsertedCommercial = t.CreateSingleCommercial(randomProgramName, account);

			Timeslot__c timeSlot = t.CreatingSingleTimeSlot(randomProgramName, allowedCommercialTime);
			timeSlot.Program_Genre__c = 'Drama';
			timeSlot.Timeslot_Date_Time__c = Date.today().addDays(1);
			insert timeSlot;

			Test.setCurrentPage(Page.CommercialScheduler);
			ApexPages.StandardController stdController = new ApexPages.StandardController(notInsertedCommercial);
			CommercialSchedulerControllerExtension extension = new CommercialSchedulerControllerExtension(stdController);
			extension.selectedProgramGenre = 'Action';

			Test.startTest();
			extension.Filter();
			Test.stopTest();

			final String expectedProgramGenre = 'Action';
			System.assert(extension.Model.size() == 1, 'Remove timeslots that are not fulfilling the criteria');
			System.assertEquals(expectedProgramGenre, extension.Model[0].GetProgramGenre(), 'Timeslots are filtered by option selected');
		}
	}

	static { BaseTest.t = new CommercialSchedulerCtrExtensionTests(); }
	static BaseTest t { get { return BaseTest.t; }}
}