package edu.kit.ipd.sdq.modsim.simspec.export.test

import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorContainer

class SMTGeneratorTestHelper {
	static def firstDelay(BehaviorContainer behavior, String name) {
		behavior.schedules.filter[startEvent.name == name].head.delay
	}
	
	static def firstWrites(BehaviorContainer behavior, String name) {
		behavior.writesAttributes.filter[event.name == name].head
	}
}