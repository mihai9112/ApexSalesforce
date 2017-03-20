@isTest
private class CommercialMasterTriggerTests extends BaseTest
{
	private static final Integer allowedCommercialTime = 30;
	private static final Integer numberOfObjectsToCreate = 101;
	private static final Integer randomNumberOfBroadcasts = 2;
	private static final String randomProgramName = 'kjgjoiyo';
	private static final String randomAccountName = 'utsrpiugtd';
	private static final String randomCommercialName = 'urstoiuujj';

	@testSetup private static void setup()
	{
		List<SObject> objectsToInsert = new List<SObject>();
		Account randomAccount = t.CreateSingleAccount(randomAccountName);
		objectsToInsert.add(randomAccount);
		Commercial__c randomCommercial = t.CreateSingleCommercial(randomCommercialName, randomAccount);
		objectsToInsert.add(randomCommercial);
		Timeslot__c randomTimeSlot = t.CreatingSingleTimeSlot(randomProgramName, allowedCommercialTime);
		objectsToInsert.add(randomTimeSlot);
		insert objectsToInsert;
		Commercial_slot__c randomCommercialSlot = t.CreateSingleCommercialSlot(randomNumberOfBroadcasts);
		randomCommercialSlot.Commercial__c = randomCommercial.Id;
		randomCommercialSlot.Timeslot__c = randomTimeSlot.Id;
		insert randomCommercialSlot;
	}

	@isTest static void CommercialSlotMasterTrigger_WhenUpdatingTheTimeOnACommercialWithAHigherValue_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			final Integer updatedRunningTimeInSeconds = 40;
			Commercial__c commercial = [Select Id, Running_Time_Seconds__c From Commercial__c];
			commercial.Running_Time_Seconds__c = updatedRunningTimeInSeconds;

			Test.startTest();
			update commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 80;
			Timeslot__c returnedTimeSlot = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.Scheduled_Commercial_Time_Seconds__c, 'When the running time for a commercial updates, the total scheduled commercial time on the timeslot must update');
		}
	}

	@isTest static void CommercialSlotMasterTrigger_WhenUpdatingTheTimeOnACommercialWithALowerValue_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			final Integer updatedRunningTimeInSeconds = 20;
			Commercial__c commercial = [Select Id, Running_Time_Seconds__c From Commercial__c];
			commercial.Running_Time_Seconds__c = updatedRunningTimeInSeconds;

			Test.startTest();
			update commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 40;
			Timeslot__c returnedTimeSlot = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.Scheduled_Commercial_Time_Seconds__c, 'When the running time for a commercial updates, the total scheduled commercial time on the timeslot must update');
		}
	}

	@isTest static void CommercialSlotMasterTrigger_WhenUpdatingTheTimeOnACommercialThatHas101CommercialSlotsWithAHigherValue_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			String commercialName = 'aihdawoihda';
			String programName = 'klajdawd';
			Integer commercialTime = 60;
			Account account = [Select Id From Account];
			Commercial__c commercial = t.CreateSingleCommercial(commercialName, account);
			Timeslot__c timeSlot = t.CreatingSingleTimeSlot(programName, commercialTime);
			List<SObject> objects = new List<SObject>();
			objects.add(commercial);
			objects.add(timeSlot);
			insert objects;
			List<Commercial_slot__c> commercialSlots = t.CreateMultipleCommercialSlots(randomNumberOfBroadcasts, numberOfObjectsToCreate, commercial);
			t.AddTimeSlotToMultipleCommercialSlots(commercialSlots, timeSlot);
			insert commercialSlots;

			final Integer updatedRunningTimeInSeconds = 40;
			commercial.Running_Time_Seconds__c = updatedRunningTimeInSeconds;

			Test.startTest();
			update commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 8080;
			Map<Id, Timeslot__c> returnedTimeSlot = new Map<Id, Timeslot__c>([Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c]);
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.get(timeSlot.Id).Scheduled_Commercial_Time_Seconds__c, 'When the running time for a commercial updates, the total scheduled commercial time on a timeslot must update');
		}
	}

	@isTest static void CommercialMasterTrigger_WhenUpdatingTheTimeOn2DifferentCommercialsThatHave101CommercialSlotsEach_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlots()
	{
		System.runAs(t.admin)
		{
			Commercial_slot__c originalCommercialSlot = [Select Id From Commercial_slot__c];
			delete originalCommercialSlot;

			String commercialName = 'lkhdawda';
			String programName = 'adkwhdawd';
			Integer commercialTime = 60;

			Account account = [Select Id From Account];
			Commercial__c firstCommercial = [Select Id From Commercial__c];
			Timeslot__c firstTimeSlot = [Select Id From Timeslot__c];
			Commercial__c secondCommercial = t.CreateSingleCommercial(commercialName, account);
			Timeslot__c secondTimeSlot = t.CreatingSingleTimeSlot(programName, commercialTime);
			List<SObject> objects = new List<SObject>();
			objects.add(secondCommercial);
			objects.add(secondTimeSlot);
			insert objects;
			List<Commercial_slot__c> commercialSlots = t.CreateMultipleCommercialSlots(randomNumberOfBroadcasts, numberOfObjectsToCreate, firstCommercial);
			t.AddTimeSlotToMultipleCommercialSlots(commercialSlots, firstTimeSlot);
			List<Commercial_slot__c> secondCommercialSlots = t.CreateMultipleCommercialSlots(randomNumberOfBroadcasts, numberOfObjectsToCreate, secondCommercial);
			t.AddTimeSlotToMultipleCommercialSlots(secondCommercialSlots, secondTimeSlot);
			commercialSlots.addAll(secondCommercialSlots);
			insert commercialSlots;

			final Integer updatedRunningTimeInSecondsForFirstCommercial = 40;
			final Integer updatedRunningTimeInSecondsForSecondCommercial = 20;

			firstCommercial.Running_Time_Seconds__c = updatedRunningTimeInSecondsForFirstCommercial;
			secondCommercial.Running_Time_Seconds__c = updatedRunningTimeInSecondsForSecondCommercial;
			List<Commercial__c> commercialsToUpdate = new List<Commercial__c>();
			commercialsToUpdate.add(firstCommercial);
			commercialsToUpdate.add(secondCommercial);

			Test.startTest();
			update commercialsToUpdate;
			Test.stopTest();

			final Integer expectedScheduledCommercialTimeForFirstTimeSlot = 8080;
			final Integer expectedScheduledCommercialTimeForSecondTimeSlot = 4040;

			List<Timeslot__c> returnedTimeSlots = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTimeForFirstTimeSlot, returnedTimeSlots[0].Scheduled_Commercial_Time_Seconds__c, 'When the running time for a commercial updates, the total scheduled commercial time on a timeslot must update');
			System.assertEquals(expectedScheduledCommercialTimeForSecondTimeSlot, returnedTimeSlots[1].Scheduled_Commercial_Time_Seconds__c, 'When the running time for a commercial updates, the total scheduled commercial time on a timeslot must update');
		}
	}

	@isTest static void CommercialMasterTrigger_WhenDeletingACommercialThatHasACommercialSlotWithATimeSlotLinkedToIt_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			Commercial__c commercial = [Select Id From Commercial__c];

			Test.startTest();
			delete commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 0;
			Timeslot__c returnedTimeSlot = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.Scheduled_Commercial_Time_Seconds__c, 'When the commercial is deleted, update the scheduled commercial time on the timeslot');
		}
	}

	@isTest static void CommercialMasterTrigger_WhenDeletingACommercialThatHas101CommercialSlotsWithATimeSlotLinkedToThem_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			Commercial_slot__c originalCommercialSlot = [Select Id From Commercial_slot__c];
			delete originalCommercialSlot;

			Commercial__c commercial = [Select Id From Commercial__c];
			Timeslot__c timeSlot = [Select Id From Timeslot__c];
			List<Commercial_slot__c> commercialSlots = t.CreateMultipleCommercialSlots(randomNumberOfBroadcasts, numberOfObjectsToCreate, commercial);
			t.AddTimeSlotToMultipleCommercialSlots(commercialSlots, timeSlot);
			insert commercialSlots;

			Test.startTest();
			delete commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 0;
			Timeslot__c returnedTimeSlot = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.Scheduled_Commercial_Time_Seconds__c, 'When the commercial is deleted, update the scheduled commercial time on the timeslot');
		}
	}

	@isTest static void CommercialMasterTrigger_WhenUndeletingACommercialThatHasACommercialSlotWithATimeSlotLinkedToIt_UpdateTheScheduledCommercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			Commercial__c commercial = [Select Id From Commercial__c];
			delete commercial;

			Test.startTest();
			undelete commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 60;
			Timeslot__c returnedTimeSlot = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.Scheduled_Commercial_Time_Seconds__c, 'When the commercial is undeleted, update the scheduled commercial time on the timeslot');
		}
	}

	@isTest static void CommercialMasterTrigger_WhenUndeletingACommercialThatHas101CommercialSlotsWithATimeSlotLinkedToThem_UpdateTheScheduledComercialTimeOnTheRelatedTimeSlot()
	{
		System.runAs(t.admin)
		{
			Commercial_slot__c originalCommercialSlot = [Select Id From Commercial_slot__c];
			delete originalCommercialSlot;

			Commercial__c commercial = [Select Id From Commercial__c];
			Timeslot__c timeSlot = [Select Id From Timeslot__c];
			List<Commercial_slot__c> commercialSlots = t.CreateMultipleCommercialSlots(randomNumberOfBroadcasts, numberOfObjectsToCreate, commercial);
			t.AddTimeSlotToMultipleCommercialSlots(commercialSlots, timeSlot);
			insert commercialSlots;
			delete commercial;

			Test.startTest();
			undelete commercial;
			Test.stopTest();

			final Integer expectedScheduledCommercialTime = 6060;
			Timeslot__c returnedTimeSlot = [Select Id, Scheduled_Commercial_Time_Seconds__c From Timeslot__c];
			System.assertEquals(expectedScheduledCommercialTime, returnedTimeSlot.Scheduled_Commercial_Time_Seconds__c, 'When the commercial is undeleted, update the scheduled commercial time on the timeslot');
		}
	}


	//Helpers
	static { BaseTest.t = new CommercialMasterTriggerTests(); }
	static BaseTest t { get { return BaseTest.t; }}

}