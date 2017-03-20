trigger CommercialMasterTrigger on Commercial__c ( before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
	private CommercialMasterTriggerHandler handler;

	if (Trigger.isBefore)
	{
		if (Trigger.isUpdate)
		{
			handler = new CommercialMasterTriggerHandler(Trigger.newMap, Trigger.oldMap);
			handler.UpdateScheduledCommercialTimeOnTimeSlots();
		}

		if (Trigger.isDelete)
		{
			handler = new CommercialMasterTriggerHandler(Trigger.oldMap);
			handler.DeleteScheduledCommercialTimeOnTimeSlots();
		}
	}

	if (Trigger.isAfter && Trigger.isUndelete)
	{
		handler = new CommercialMasterTriggerHandler(Trigger.newMap);
		handler.AddScheduledCommercialTimeOnTimeSlots();
	}
}