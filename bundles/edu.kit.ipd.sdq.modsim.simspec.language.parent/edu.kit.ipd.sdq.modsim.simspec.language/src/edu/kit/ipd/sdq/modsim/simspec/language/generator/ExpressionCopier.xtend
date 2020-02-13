package edu.kit.ipd.sdq.modsim.simspec.language.generator

import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.EObject
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.ExpressionsFactory
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Constant
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.DefinitionReference
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.TypeCast
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.UnaryOperator

class ExpressionCopier extends EcoreUtil.Copier {
	override copy(EObject object) {
		// subclasses of Constant only exist in the language model to make parsing/typing easier.
		// this converts them to simple constant objects
		if (object instanceof Constant)
			return ExpressionsFactory.eINSTANCE.createConstant => [
				value = object.value 
				type = object.type
			]
		if (object instanceof TypeCast)
			return ExpressionsFactory.eINSTANCE.createUnaryOperation => [
				operator = UnaryOperator.TYPE_CAST
				operand = object.expression
				type = object.type // after typing, object.type is the same as object.targetType
			]
		// resolve definition references
		if (object instanceof DefinitionReference)
			return copy(object.definition.expression)
			
		return super.copy(object)
	}
}