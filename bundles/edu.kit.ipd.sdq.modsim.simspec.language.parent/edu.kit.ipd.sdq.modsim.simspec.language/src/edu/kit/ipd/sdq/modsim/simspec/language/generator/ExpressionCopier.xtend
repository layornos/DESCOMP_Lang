package edu.kit.ipd.sdq.modsim.simspec.language.generator

import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.EObject
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.ExpressionsFactory
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Constant

class ExpressionCopier extends EcoreUtil.Copier {
	override copy(EObject object) {
		if (object instanceof Constant)
			return ExpressionsFactory.eINSTANCE.createConstant => [
				value = object.value 
				type = object.type
			]
		return super.copy(object)
	}
}