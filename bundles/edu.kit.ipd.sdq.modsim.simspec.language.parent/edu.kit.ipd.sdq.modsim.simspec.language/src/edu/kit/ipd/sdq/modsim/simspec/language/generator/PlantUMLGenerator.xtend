package edu.kit.ipd.sdq.modsim.simspec.language.generator

import java.util.List
import edu.kit.ipd.sdq.modsim.simspec.language.specificationLanguage.SimFeature
import edu.kit.ipd.sdq.modsim.simspec.model.behavior.BehaviorContainer

class PlantUMLGenerator {
	static def generateEventDiagram(List<SimFeature> features, BehaviorContainer behavior) '''
		@startuml
		hide circle
		skinparam classFontName Helvetica
		skinparam roundcorner 12
		skinparam class {
			BackgroundColor #f28886
			FontColor #222222
			ArrowColor #333333
			BorderColor #444444
			BorderThickness 0.5
		}
		skinparam package {
			BorderColor #444444
			BorderThickness 0.5
		}
		
		skinparam Padding 6
		skinparam shadowing false
		
		hide members
		
		«FOR feature : features»
		package «feature.name» {
			«FOR e : feature.events»
			class «e.name»
			«ENDFOR»
		}
		«ENDFOR»
		
		«FOR sched : behavior.schedules»
		«sched.startEvent.name» --> «sched.endEvent.name»
		«ENDFOR»
		@enduml
	'''
}