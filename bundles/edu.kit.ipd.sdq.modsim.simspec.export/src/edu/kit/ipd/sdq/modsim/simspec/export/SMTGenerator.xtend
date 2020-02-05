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
import java.util.Set
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension edu.kit.ipd.sdq.modsim.simspec.model.datatypes.TypeUtil.*

class SMTGenerator {
	
	new() {
		
	}
	
	/**
	 * Generates the complete SMT code for a delay. Delays are always of sort 'Real'.
	 * 
	 * @param delayExpr The expression that defines the value of the delay. Must be a number.
	 * @return A set of SMT commands that specify the delay.
	 */
	def String generateDelay(Expression delayExpr) {
		if (!delayExpr.type.isNumberType)
			throw new IllegalArgumentException('Delay must be a number, but has type: ' + delayExpr.type)
		
		val attributes = delayExpr.findReferencedAttributes
		
		'''
		(declare-fun delay () Real)
		«FOR attr : attributes»
		«attr.toVariableDeclaration»
		«ENDFOR»
		(assert (= delay «delayExpr.generateExpressionAndCast(createDoubleType)»))
		'''
	}
	
	/**
	 * Generates the complete SMT code for a write function.
	 * 
	 * @param attribute The attribute that is overwritten by the write function. Its name and type are used to create an SMT variable. 
	 * @param writeFunction The expression that defines the value to write. Must have a type compatible with the type of attribute.
	 * @return A set of SMT commands that specify the write function.
	 */
	def String generateWritesAttribute(Attribute attribute, Expression writeFunction) {
		if (!writeFunction.type.compatible(attribute.type))
			throw new IllegalArgumentException('Incompatible types: ' + writeFunction.type + ' and ' + attribute.type)
			
		val attributes = writeFunction.findReferencedAttributes
		
		'''
		(declare-fun value () «attribute.type.toSMTSort»)
		«FOR attr : attributes»
		«attr.toVariableDeclaration»
		«ENDFOR»
		(assert (= value «writeFunction.generateExpressionAndCast(attribute.type)»))
		'''
	}
	
	/**
	 * Generates the complete SMT code for a condition. Conditions are always of sort 'Bool'.
	 * 
	 * @param condition The expression that defines the condition.
	 * @return A set of SMT commands that specify the condition.
	 */
	def String generateCondition(Expression condition) {
		if (!condition.type.isBoolType)
			throw new IllegalArgumentException('Condition must be a bool, but has type: ' + condition.type)
		
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
			// special treatment for division, '/' is only defined for Reals
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
		val Set<Attribute> references = newHashSet
		val contents = EcoreUtil.getAllContents(#[expr])
		
		contents.filter(Variable).forEach[references.add(attribute)]
		
		return references
	}
	
	def toVariableDeclaration(Attribute attribute) '''
		(declare-fun «attribute.name» () «attribute.type.toSMTSort»)
	'''
	
	/**
	 * Returns the string representation of the SMT sort to a given {@link DataType}.
	 * 
	 * @param type The data type.
	 * @return The corresponding SMT sort. 
	 */
	def String toSMTSort(DataType type) {
		switch type {
			BaseDataType : type.toPrimitiveSMTSort
			ArrayDataType : '''(Array Int «type.contentType.toSMTSort»)'''
			default: throw new IllegalArgumentException('Unknown type: ' + type)
		}
	}
	
	/**
	 * Returns the string representation of the SMT sort to a given {@link BaseDataType}.
	 * 
	 * @param type The primitive type.
	 * @return The corresponding SMT sort. 
	 */
	def toPrimitiveSMTSort(BaseDataType type) {
		switch type.primitiveType {
			case PrimitiveType.INT: 'Int'
			case PrimitiveType.DOUBLE: 'Real'
			case PrimitiveType.BOOL: 'Bool'
			default: throw new IllegalArgumentException('Unknown type: ' + type.primitiveType)
		}
	}
}