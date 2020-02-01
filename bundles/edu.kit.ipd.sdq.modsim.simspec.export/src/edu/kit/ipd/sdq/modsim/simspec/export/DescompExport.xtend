package edu.kit.ipd.sdq.modsim.simspec.export

import edu.kit.ipd.sdq.modsim.simspec.model.structure.Simulator
import edu.kit.ipd.sdq.modsim.simspec.model.structure.StructurePackage
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.neo4j.ogm.config.Configuration
import org.neo4j.ogm.session.SessionFactory
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Entity
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Attribute
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Event
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorContainer
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.DataType
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.BaseDataType
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Schedules
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.WritesAttribute

class DescompExport {
	
	def void uploadSimulator(URI uri) {
		StructurePackage.eINSTANCE.eClass
		
		val reg = Resource.Factory.Registry.INSTANCE
		reg.extensionToFactoryMap.put("structure", new XMIResourceFactoryImpl)
		val resSet = new ResourceSetImpl
		
		val resource = resSet.getResource(uri, true)
		
		val sim = resource.contents.filter(Simulator).head
		val behavior = resource.contents.filter(BehaviorContainer).head
		
		
		
		val generator = new SMTGenerator(sim)
		
		val simExport = sim.export
		val schedules = behavior.schedules.map[exportSchedules(generator)]
		val writes = behavior.writesAttributes.map[exportWritesAttribute(generator)]
		
		// save to database
		val config = new Configuration.Builder()
			.uri('bolt://localhost:7687')
			.credentials('neo4j', 'ZtA6tdah1FxB')
			.build()
		val factory = new SessionFactory(config, 'edu.kit.ipd.sdq.modsim.simspec.export')
		
		println('start connecting')
		val session = factory.openSession
		println('connected!')
		
		//val conflicting = session.loadAll(DataSimulator, new Filter('name', ComparisonOperator.EQUALS, simExport.name), 4)
		//session.delete(conflicting)
		//session.purgeDatabase
		
		session.save(simExport)
		session.save(schedules)
		session.save(writes)
		
		println('saved!')
		
		factory.close
	}
	
	def exportSchedules(Schedules schedules, SMTGenerator generator) {
		new DescompSchedules => [
			startEvent = schedules.startEvent.export
			endEvent = schedules.endEvent.export
		
			delay = generator.generateDelay(schedules.delay)
			condition = generator.generateCondition(schedules.condition)
		]
	}
	
	def exportWritesAttribute(WritesAttribute writes, SMTGenerator generator) {
		new DescompWritesAttribute => [
			startEvent = writes.event.export
			attribute = writes.attribute.export
			
			writeFunction = generator.generateWritesAttribute(writes.attribute, writes.writeFunction)
			condition = generator.generateCondition(writes.condition)
		]
	}
	
	def create result: new DescompSimulator export(Simulator sim) {
		result.name = sim.name
		result.entities = sim.entities.map[export].toSet
		result.events = sim.events.map[export].toSet
	}
	
	def create result: new DescompEntity export(Entity entity) {
		result.name = entity.name
		result.attributes = entity.attributes.map[export].toSet
	}
	
	def create result: new DescompAttribute export(Attribute attribute) {
		result.name = attribute.name
		result.type = attribute.type.typeName
	}
	
	def create result: new DescompEvent export(Event event) {
		result.name = event.name
		result.readAttribute = event.readAttributes.map[export].toSet
	}
	
	def typeName(DataType type) {
		if (type instanceof BaseDataType)
			return type.primitiveType.toString
		return 'UNKNOWN TYPE'
	}
}