package edu.kit.ipd.sdq.modsim.simspec.language.ui

import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Expression
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.BaseDataType
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.EnumType
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.ArrayDataType

class SpecificationLanguageEObjectHoverProvider extends DefaultEObjectHoverProvider {
	
	override getFirstLine(EObject object) {
		if (object instanceof Expression)
			//return object.type.toString()
			return object.type.typeName
			
		return super.getFirstLine(object)
	}
	
	def dispatch typeName(BaseDataType type) {
		type.primitiveType.toString
	}
	
	def dispatch typeName(EnumType type) {
		type.declaration.name
	}
	
	def dispatch String typeName(ArrayDataType type) {
		'Array of ' + type.contentType.typeName
	}
}