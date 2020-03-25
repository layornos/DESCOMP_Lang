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
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.EnumDeclarationContainer
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Simulator

/**
 * Transforms an instance of the Xtext language model (simspec.language.SpecificationLanguage) 
 * to an instance of the modular simulation model (simspec.model). Initialize the transform
 * with a root {@link SimSpecification} object and call {@link #transform}.
 * 
 * @author Eric Hamann
 */
class SimulationModelTransform {
	val SimSpecification source

	// Keep a behavior container to avoid passing it through all create-methods
	BehaviorContainer behavior

	new(SimSpecification source) {
		this.source = source
	}

	/**
	 * Transforms the {@link SimSpecification} to a list of EObjects that represent the simulation
	 * according to the modular simulation model (simspec.model).
	 * 
	 * @return A list of three objects: A {@link Simulator}, a {@link BehaviorContainer} 
	 * and an {@link EnumDeclarationContainer}.
	 */
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

	// events, schedules and writes are copied with custom copy-methods instead of an EcoreUtil.Copier,
	// because the number of classes is quite low compared to expressions and Xtend create-methods 
	// are easier to implement than a custom EcoreUtil.copier.
	
	private def create result: StructureFactory.eINSTANCE.createEvent transformEvent(Event e) {
		e.copyNameAndIdentifierTo(result)
		result.readAttributes.addAll(e.readAttributes.clone)

		if (e instanceof GEvent) {
			e.schedules.forEach[transformSchedules(result)]
			e.writeAttributes.forEach[transformWrites(result)]
		}
	}

	private def transformSchedules(GSchedules schedules, Event event) {
		// get expressions or use default
		val delayExpr = schedules.delaySpec?.delay ?: createDefaultDelay
		val conditionExpr = schedules.conditionSpec?.condition ?: createDefaultCondition
		
		val sched = BehaviorFactory.eINSTANCE.createSchedules => [
			startEvent = event
			endEvent = transformEvent(schedules.endEvent)
			
			delay = copyExpression(delayExpr)
			condition = copyExpression(conditionExpr)
		]

		behavior.schedules.add(sched)
	}

	private def transformWrites(GWritesAttribute writes, Event e) {
		// get write condition or use default
		val conditionExpr = writes.conditionSpec?.condition ?: createDefaultCondition
		
		val write = BehaviorFactory.eINSTANCE.createWritesAttribute => [
			event = e
			attribute = writes.writeFunction.attribute
			
			val function = writes.writeFunction
			writeFunction = switch (function) {
				WriteToValue: copyExpression(function.value)
				WriteToArray: createArrayWrite(function)
			}
			
			condition = copyExpression(conditionExpr)
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
		// Create an array writes expression where the array is a variable defined in the function-parameter.
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

	private def copyNameAndIdentifierTo(NamedIdentifier src, NamedIdentifier dest) {
		dest.id = src.id
		dest.name = src.name
	}
}
