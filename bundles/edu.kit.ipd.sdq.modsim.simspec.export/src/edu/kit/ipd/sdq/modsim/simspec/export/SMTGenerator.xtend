package edu.kit.ipd.sdq.modsim.simspec.export

import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Expression
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.ArrayDataType
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.BaseDataType
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.DataType
import edu.kit.ipd.sdq.modsim.simspec.model.datatypes.PrimitiveType
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Comparator
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Comparison
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Constant
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.IfThenElse
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Operation
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Operator
import edu.kit.ipd.sdq.modsim.simspec.model.expressions.Variable
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Attribute
import edu.kit.ipd.sdq.modsim.simspec.model.structure.Simulator
import java.util.List
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension edu.kit.ipd.sdq.modsim.simspec.model.datatypes.TypeUtil.*

class SMTGenerator {
	//val Simulator context
	
	new(Simulator context) {
		//this.context = context
	}
	
	def String generateDelay(Expression delayExpr) {
		val attributes = delayExpr.findReferencedAttributes
		
		'''
		(declare-fun delay () Real)
		«FOR attr : attributes»
		«attr.toVariableDeclaration»
		«ENDFOR»
		(assert (= delay «delayExpr.generateExpressionAndCast(createDoubleType)»))
		'''
	}
	
	def String generateWritesAttribute(Attribute attribute, Expression writeFunction) {
		val attributes = writeFunction.findReferencedAttributes
		
		'''
		(declare-fun value () «attribute.type.toSMTType»)
		«FOR attr : attributes»
		«attr.toVariableDeclaration»
		«ENDFOR»
		(assert (= value «writeFunction.generateExpressionAndCast(attribute.type)»))
		'''
	}
	
	def String generateCondition(Expression condition) {
		val attributes = condition.findReferencedAttributes
		
		'''
		«FOR attr : attributes»
		«attr.toVariableDeclaration»
		«ENDFOR»
		(assert «condition.generateExpression»)
		'''
	}
	
	def String generateExpressionAndCast(Expression expr, DataType targetType) {
		val generated = expr.generateExpression
		
		if (typesEqual(expr.type, targetType))
			generated
		// expression is int, needs to be double
		else if (expr.type.isIntType && targetType.isDoubleType)
			'''(to_real «generated»)'''
		// other way around
		else if (expr.type.isDoubleType && targetType.isIntType)
			'''(to_int «generated»)'''
	}
	
	def dispatch String generateExpression(Operation operation) {
		val operator = operation.operator.generateOperator(operation.left.type, operation.right.type)
		val left = operation.left.generateExpressionAndCast(operation.type)
		val right = operation.right.generateExpressionAndCast(operation.type)
		
		'''(«operator» «left» «right»)'''
	}
	
	def dispatch String generateExpression(Comparison comparison) {
		val comparedType = combinedType(comparison.left.type, comparison.right.type)
		
		val comparator = comparison.comparator.generateComparator
		val left = comparison.left.generateExpressionAndCast(comparedType)
		val right = comparison.right.generateExpressionAndCast(comparedType)
		
		'''(«comparator» «left» «right»)'''
	}
	
	def dispatch String generateExpression(IfThenElse ite) {
		val condition = ite.condition.generateExpression
		val thenBranch = ite.thenBranch.generateExpressionAndCast(ite.type)
		val elseBranch = ite.elseBranch.generateExpressionAndCast(ite.type)
		
		'''(ite «condition» «thenBranch» «elseBranch»)'''
	}
	
	def dispatch generateExpression(Constant constant) {
		constant.value
	}
	
	def dispatch generateExpression(Variable variable) {
		variable.attribute.name
	}
	
	def generateOperator(Operator operator, DataType leftType, DataType rightType) {
		switch operator {
			case Operator.PLUS: '+'
			case Operator.MINUS: '-'
			case Operator.MULT: '*'
			case Operator.DIV: if (leftType.isIntType && rightType.isIntType) 'div' else '/'
			default: throw new IllegalArgumentException('Unknown operator: ' + operator)
		}
	}
	
	def generateComparator(Comparator comparator) {
		switch comparator {
			case Comparator.EQUAL: '='
			case Comparator.LESS_THAN: '<'
			case Comparator.LESS_THAN_EQUAL: '<='
			case Comparator.GREATER_THAN: '>'
			case Comparator.GREATER_THAN_EQUAL: '>='
			default: throw new IllegalArgumentException('Unknown operator: ' + comparator)
		}
	}
	
	def findReferencedAttributes(Expression expr) {
		val List<Attribute> references = newArrayList
		val contents = EcoreUtil.getAllContents(#[expr])
		
		contents.filter(Variable).forEach[
			if (!references.exists[a | a.id == attribute.id])
				references.add(attribute)
		]
		
		return references
	}
	
	def toVariableDeclaration(Attribute attribute) '''
		(declare-fun «attribute.name» () «attribute.type.toSMTType»)'''
	
	def String toSMTType(DataType type) {
		switch type {
			BaseDataType : type.primitiveSMTType
			ArrayDataType : '''(Array Int «type.contentType.toSMTType»)'''
			default: throw new IllegalArgumentException('Unknown type: ' + type)
		}
	}
	
	def primitiveSMTType(BaseDataType type) {
		switch type.primitiveType {
			case PrimitiveType.INT: 'Int'
			case PrimitiveType.DOUBLE: 'Real'
			case PrimitiveType.BOOL: 'Bool'
			default: throw new IllegalArgumentException('Unknown type: ' + type.primitiveType)
		}
	}
}