/*
 * generated by Xtext 2.17.0
 */
package edu.kit.ipd.sdq.modsim.simspec.language.validation

import org.eclipse.xtext.validation.Check
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.EnumLiteral
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.ExpressionsPackage

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class SpecificationLanguageValidator extends AbstractSpecificationLanguageValidator {

	@Check
	def checkEnumContainsLiteral(EnumLiteral enumLiteral) {
		val declaration = enumLiteral.declaration
		if (!declaration.literals.contains(enumLiteral.value)) {
			error('Enum ' + declaration.name + ' does not contain literal ' + enumLiteral.value,
				ExpressionsPackage.Literals.CONSTANT__VALUE)
		}
	}

//	public static val INVALID_NAME = 'invalidName'
//
//	@Check
//	def checkGreetingStartsWithCapital(Greeting greeting) {
//		if (!Character.isUpperCase(greeting.name.charAt(0))) {
//			warning('Name should start with a capital', 
//					SpecificationLanguagePackage.Literals.GREETING__NAME,
//					INVALID_NAME)
//		}
//	}
//	@Check
//	def checkExpressionTest(Expression expr) {
//		
//	}
//	
}
