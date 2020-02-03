package edu.kit.ipd.sdq.modsim.simspec.language.typing

import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.Definition
import java.util.HashSet
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Expression
import java.util.Set
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.DefinitionReference

class DefinitionUtil {
	static def containsCycles(Definition definition) {
		val visited = new HashSet<Definition>
		val finished = new HashSet<Definition>
		
		return traverseChildren(definition.expression, visited, finished)
	}
	
	private static def boolean traverseChildren(Expression expr, Set<Definition> visited, Set<Definition> finished) {
		val children = (expr.eContents + expr.eCrossReferences).filter(Expression)
		
		if (expr instanceof DefinitionReference) {
			if (finished.contains(expr.definition)) return false
			if (visited.contains(expr.definition)) return true
			
			visited.add(expr.definition)
			val containsCycles = traverseChildren(expr.definition.expression, visited, finished)
			finished.add(expr.definition)
			return containsCycles
		}
		
		return children.map[traverseChildren(visited, finished)].any
	}
	
	private static def boolean any(Iterable<Boolean> iterable) {
		return iterable.exists[it == true]
	}
}