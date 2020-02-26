package edu.kit.ipd.sdq.modsim.simspec.language.generator

import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GEvent
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GSchedules
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GWritesAttribute
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.SimSpecification
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.WriteToArray
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.WriteToValue
import edu.kit.ipd.sdq.modsim.simspec.model.arrayoperations.ArrayoperationsFactory
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorContainer
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorFactory
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Expression
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.DatatypesFactory
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.TypeUtil
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.ExpressionsFactory
import edu.kit.ipd.sdq.modsim.simspec.model.general.NamedIdentifier
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Event
import edu.kit.ipd.sdq.modsim.simspec.model.structure.StructureFactory
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil

class SimulationModelTransform {
	val SimSpecification source

	BehaviorContainer behavior

	new(SimSpecification source) {
		this.source = source
	}

	def List<EObject> transform() {
		val features = source.features
		
		val entities = features.map[entities.clone.toList].flatten
		val events = features.map[events.clone.toList].flatten
		val declarations = features.map[enums.clone.toList].flatten
		
		// Init model root objects
		val sim = StructureFactory.eINSTANCE.createSimulator
		behavior = BehaviorFactory.eINSTANCE.createBehaviorContainer
		val enums = DatatypesFactory.eINSTANCE.createEnumDeclarationContainer
		
		sim.name = source.name
		sim.description = source.description
		// Entites and enum declarations need no change in their structure, so they are just added to their new containers.
		// (that also keeps the references) 
		sim.entities.addAll(entities)
		enums.declarations.addAll(declarations)
		
		val eventsCopy = events.map[transformEvent].clone
		sim.events.addAll(eventsCopy)

		#[sim, behavior, enums]
	}

	private def create result: StructureFactory.eINSTANCE.createEvent transformEvent(Event e) {
		e.copyNamedIdentifier(result)
		result.readAttributes.addAll(e.readAttributes.clone)

		if (e instanceof GEvent) {
			e.schedules.forEach[transformSchedules(result)]
			e.writeAttributes.forEach[transformWrites(result)]
		}
	}

	private def transformSchedules(GSchedules schedules, Event event) {
		val sched = BehaviorFactory.eINSTANCE.createSchedules => [
			startEvent = event
			endEvent = transformEvent(schedules.endEvent)
			// TODO: validate expression types
			delay = copyExpression(schedules.delaySpec?.delay ?: createDefaultDelay)
			condition = copyExpression(schedules.conditionSpec?.condition ?: createDefaultCondition)
		]

		behavior.schedules.add(sched)
	}

	private def transformWrites(GWritesAttribute writes, Event e) {
		val write = BehaviorFactory.eINSTANCE.createWritesAttribute => [
			event = e
			attribute = writes.writeFunction.attribute
			// TODO: validate expression types
			
			val function = writes.writeFunction
			writeFunction = switch (function) {
				WriteToValue: copyExpression(function.value)
				WriteToArray: createArrayWrite(function)
			}
			
			condition = copyExpression(writes.conditionSpec?.condition ?: createDefaultCondition)
		]

		behavior.writesAttributes.add(write)
	}

	private def copyExpression(Expression expr) {
		// Since expressions don't contain cycles, it's easier to copy them with a custom EcoreUtil.Copier than
		// to add create-methods for each Expression subclass. 
		val copier = new ExpressionCopier();
    	val result = copier.copy(expr);
    	copier.copyReferences();
    	return result as Expression
	}
	
	private def createArrayWrite(WriteToArray function) {
		ArrayoperationsFactory.eINSTANCE.createArrayWrite => [
			type = EcoreUtil.copy(function.attribute.type)
			array = ExpressionsFactory.eINSTANCE.createVariable => [
				attribute = function.attribute
				type = EcoreUtil.copy(function.attribute.type)
			]
			index = copyExpression(function.index)
			value = copyExpression(function.value)
		]
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
