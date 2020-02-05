package edu.kit.ipd.sdq.modsim.simspec.language.typing

import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.Definition
import java.util.HashSet
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.Expression
import java.util.Set
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.DefinitionReference

class DefinitionUtil {
	/**
	 * Checks if the syntax tree of a given {@link Definition} contains a cycle, i.e. if the definition directly
	 * of indirectly references itself.
	 * 
	 * @param definition The definition to check. The search for cycles starts at the expression of this definition.
	 * @return true iff the definition contains a cycle.
	 */
	static def containsCycles(Definition definition) {
		// only visit definitions during DFS since only definitions can induce cycles
		val visited = new HashSet<Definition>
		val finished = new HashSet<Definition>
		
		return cycleDFS(definition.expression, visited, finished)
	}
	
	private static def boolean cycleDFS(Expression expr, Set<Definition> visited, Set<Definition> finished) {
		// get all children of this expression, contents AND references (definition cycles only exist through references)
		val children = (expr.eContents + expr.eCrossReferences).filter(Expression)
		
		// only do a DFS step when this expression is a def. reference (i.e. it could be part of a cycle)
		if (expr instanceof DefinitionReference) {
			if (finished.contains(expr.definition)) return false
			if (visited.contains(expr.definition)) return true
			
			visited.add(expr.definition)
			// recursively search for cycles in the expression of the referenced definition
			val containsCycles = cycleDFS(expr.definition.expression, visited, finished)
			finished.add(expr.definition)
			
			return containsCycles
		}
				
		// otherwise just check all children for cycles
		return children.map[cycleDFS(visited, finished)].exists[it]
	}
}