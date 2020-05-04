package edu.kit.ipd.sdq.modsim.simspec.export.test

import static org.junit.jupiter.api.Assertions.*

import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import edu.kit.ipd.sdq.modsim.simspec.export.SMTGenerator
import org.junit.jupiter.api.Assertions
import edu.kit.ipd.sdq.modsim.simspec.model.structure.StructurePackage
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.common.util.URI
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Simulator
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorContainer
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.ExpressionsPackage
import edu.kit.ipd.sdq.modsim.simspec.model.arrayoperations.ArrayoperationsPackage

import static extension edu.kit.ipd.sdq.modsim.simspec.export.test.SMTGeneratorTestHelper.*

class SMTGeneratorTest {
	static Simulator sim
	static BehaviorContainer behavior
	static val generator = new SMTGenerator
	
	@BeforeAll
	static def void setUpBeforeClass() throws Exception {
		// make sure all necessary packages are loaded!
		StructurePackage.eINSTANCE.eClass
		ExpressionsPackage.eINSTANCE.eClass
		ArrayoperationsPackage.eINSTANCE.eClass
		
		// init resources
		val reg = Resource.Factory.Registry.INSTANCE
		reg.extensionToFactoryMap.put("structure", new XMIResourceFactoryImpl)
		val resSet = new ResourceSetImpl
		
		val fileUri = URI.createFileURI('resources/generated.structure')
		val resource = resSet.getResource(fileUri, true)
		
		// load test simulator from ecore file
		sim = resource.contents.filter(Simulator).head
		behavior = resource.contents.filter(BehaviorContainer).head
	}

	@Test
	def testVariables() {
		val delay = behavior.firstDelay('Variables')
		val smt = generator.generateDelay(delay)
		
		Assertions.assertEquals('''
		(declare-fun delay () Real)
		(declare-fun value () Int)
		(assert (= delay (to_real value)))
		'''.toString(), smt)
	}
	
	@Test
	def testTypes() {
		val writes = behavior.firstWrites('Types')
		val smt = generator.generateWritesAttribute(writes.attribute, writes.writeFunction)
		
		Assertions.assertEquals('''
		(declare-fun value () Type)
		(declare-datatypes ((Type 0)) (( (A)  (B) )))
		(assert (= value A))
		'''.toString(), smt)
	}
	
	@Test
	def testArithmetic() {
		val delay = behavior.firstDelay('Arithmetic')
		val smt = generator.generateDelay(delay)
		
		Assertions.assertEquals('''
		(declare-fun delay () Real)
		(declare-fun value () Int)
		(assert (= delay (+ (to_real value) (* (to_real 2) 4.0))))
		'''.toString(), smt)
	}
}