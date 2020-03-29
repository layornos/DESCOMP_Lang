/*
 * generated by Xtext 2.17.0
 */
package edu.kit.ipd.sdq.modsim.simspec.language.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.SimFeature
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.GEvent
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.DefinitionReference
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.EnumType
import org.eclipse.xtext.testing.validation.ValidationTestHelper

@ExtendWith(InjectionExtension)
@InjectWith(SpecificationLanguageInjectorProvider)
class SpecificationLanguageParsingTest {
	@Inject
	ParseHelper<SimFeature> parseHelper
	
	@Inject extension
	ValidationTestHelper
	
	@Test
	def void createEntity() {
		val result = parseHelper.parse('''
			feature F
			
			entity Ent {
				
			}
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: �errors.join(", ")�''')
	}
	
	@Test
	def void createAttributes() {
		val result = parseHelper.parse('''
			feature F
			
			entity Ent {
				attr1: INT
				zahl: DOUBLE
				wert: BOOL
			}
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: �errors.join(", ")�''')
		
		val feature = result as SimFeature
		val entity = feature.entities.head
		Assertions.assertSame(entity.attributes.size, 3)
	}
	
	@Test
	def void createAttributesFail() {
		val result = parseHelper.parse('''
			feature F
			
			entity Ent {
				attr1: INT
				zahl: DOU
			}
		''')
		//Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void createEvent() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				schedules E with delay = 0
			}
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: �errors.join(", ")�''')
		
		val feature = result as SimFeature
		val event = feature.events.filter(GEvent).head
		Assertions.assertNotNull(event.schedules.head.delaySpec)
		Assertions.assertNull(event.schedules.head.conditionSpec)
	}
	
	@Test
	def void createEventFail() {
		val result = parseHelper.parse('''
			feature F
						
			event E {
				schedules F
			}
		''')
		val errors = result.eResource.errors
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void createEventFail2() {
		val result = parseHelper.parse('''
			feature F
						
			event E {
				schedules E with delay
			}
		''')
		val errors = result.eResource.errors
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void createEventCondition() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				schedules E with delay = 0
					when true
				
			}
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: �errors.join(", ")�''')
		
		val feature = result as SimFeature
		val event = feature.events.filter(GEvent).head
		Assertions.assertNotNull(event.schedules.head.conditionSpec)
	}
	
	@Test
	def void definitionComplex() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				def value = if true then 1 else 2
				
				schedules E with delay = $value
			}
		''');
		val feature = result as SimFeature
		val event = feature.events.filter(GEvent).head
		Assertions.assertTrue(event.schedules.head.delaySpec.delay instanceof DefinitionReference)
		Assertions.assertSame((event.schedules.head.delaySpec.delay as DefinitionReference).definition, event.definitions.head)
	}
	
	@Test
	def void createWrites() {
		val result = parseHelper.parse('''
			feature F
			
			entity Ent {
				num: INT
			}
			
			event E {
				reads Ent.num
				
				writes Ent.num = num + 1
			}
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: �errors.join(", ")�''')
		
		val feature = result as SimFeature
		val attribute = feature.entities.head.attributes.head
		val event = feature.events.filter(GEvent).head
		Assertions.assertNotNull(event.writeAttributes.head)
		Assertions.assertSame(event.readAttributes.size, 1)
		Assertions.assertSame(event.readAttributes.head, attribute)
	}
	
	@Test
	def void createDatatype() {
		val result = parseHelper.parse('''
			feature F
			
			datatype Type {
				LitA, LitB
			}
			
			entity E {
				wert: Type
			}
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: �errors.join(", ")�''')
		
		val feature = result as SimFeature
		val decl = feature.enums.head
		val attribute = feature.entities.head.attributes.head
		Assertions.assertTrue(attribute.type instanceof EnumType)
		Assertions.assertSame((attribute.type as EnumType).declaration, decl)
	}
	
	@Test
	def void missingReads() {
		val result = parseHelper.parse('''
			feature F
			
			entity Ent {
				num: INT
			}
			
			event E {
				writes Ent.num = num + 1
			}
		''')
		val errors = result.eResource.errors
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void typingFail() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				schedules E with delay = true
			}
		''')
		val errors = validate(result)
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void typingFail2() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				schedules E with delay = if true then 1 else (1 + false)
			}
		''')
		val errors = validate(result)
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void typingFail3() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				def value = 1 + true
				
				schedules E with delay = 0
			}
		''')
		val errors = validate(result)
		Assertions.assertFalse(errors.isEmpty)
	}
	
	@Test
	def void definitionCycles() {
		val result = parseHelper.parse('''
			feature F
			
			event E {
				def a = $b
				def b = $a
				
				schedules E with delay = 0
			}
		''')
		val errors = validate(result)
		Assertions.assertFalse(errors.isEmpty)
	}
}
