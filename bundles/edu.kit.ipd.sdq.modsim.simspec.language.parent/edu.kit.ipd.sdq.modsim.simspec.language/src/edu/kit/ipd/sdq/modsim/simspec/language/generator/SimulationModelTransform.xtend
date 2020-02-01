package edu.kit.ipd.sdq.modsim.simspec.language.generator

import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GEvent
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GSchedules
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GWritesAttribute
import edu.kit.ipd.sdq.modsim.simspec.language.typing.TypeUtil
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorContainer
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorFactory
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Expression
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.ExpressionsFactory
import edu.kit.ipd.sdq.modsim.simspec.model.general.NamedIdentifier
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Event
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Simulator
import edu.kit.ipd.sdq.modsim.simspec.model.structure.StructureFactory
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource

class SimulationModelTransform {
	val Resource source

	BehaviorContainer behavior

	new(Resource source) {
		this.source = source
	}

	def List<EObject> transform() {
		// Init resources: simulator and behavior container
		val sim = source.allContents.filter(Simulator).head as Simulator;
		behavior = BehaviorFactory.eINSTANCE.createBehaviorContainer

		val events = sim.events.map[transformEvent].clone

		sim.events.clear
		sim.events.addAll(events)

		#[sim, behavior]
	}

	private def create result: StructureFactory.eINSTANCE.createEvent transformEvent(Event e) {
		e.copyNamedIdentifier(result)
		result.readAttributes.addAll(e.readAttributes.clone)

		if (e instanceof GEvent) {
			e.schedules.forEach[s | transformSchedules(result, s)]
			e.writeAttributes.forEach[w | transformWrites(result, w)]
		}
	}

	private def transformSchedules(Event event, GSchedules schedules) {
		val sched = BehaviorFactory.eINSTANCE.createSchedules => [
			startEvent = event
			endEvent = transformEvent(schedules.endEvent)
			// TODO: validate expression types
			delay = copyExpression(schedules.delaySpec?.delay ?: createDefaultDelay)
			condition = copyExpression(schedules.conditionSpec?.condition ?: createDefaultCondition)
		]

		behavior.schedules.add(sched)
	}

	private def transformWrites(Event e, GWritesAttribute writes) {
		val write = BehaviorFactory.eINSTANCE.createWritesAttribute => [
			event = e
			attribute = writes.writeFunction.attribute
			// TODO: validate expression types
			writeFunction = copyExpression(writes.writeFunction.value)
			condition = copyExpression(writes.conditionSpec?.condition ?: createDefaultCondition)
		]

		behavior.writesAttributes.add(write)
	}

	private def copyExpression(Expression expr) {
		val copier = new ExpressionCopier();
    	val result = copier.copy(expr);
    	copier.copyReferences();
    	return result as Expression
	}
	
	private def createDefaultDelay() {
		ExpressionsFactory.eINSTANCE.createConstant => [
			value = '0.0'
			type = TypeUtil.createDoubleType
		]	
	}
	
	private def createDefaultCondition() {
		ExpressionsFactory.eINSTANCE.createConstant => [
			value = 'true'
			type = TypeUtil.createBoolType
		]	
	}

	private def copyNamedIdentifier(NamedIdentifier src, NamedIdentifier dest) {
		dest.id = src.id
		dest.name = src.name
	}
}
