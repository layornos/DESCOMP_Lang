package edu.kit.ipd.sdq.modsim.simspec.plugin

import org.eclipse.debug.ui.ILaunchShortcut
import org.eclipse.jface.viewers.ISelection
import org.eclipse.ui.IEditorPart
import org.eclipse.jface.viewers.IStructuredSelection
import org.eclipse.core.internal.resources.File
import org.eclipse.emf.common.util.URI
import edu.kit.ipd.sdq.modsim.simspec.export.DescompExport

class LaunchShortcut implements ILaunchShortcut {
	
	override launch(ISelection selection, String mode) {
		if (!(selection instanceof IStructuredSelection)) {
			//TODO: useful error message
			return
		}
		
		val structured = selection as IStructuredSelection
		
		if (!(structured.firstElement instanceof File)) {
			//TODO: another useful error
			return
		}
		
		val file = structured.firstElement as File
		val projectRoot = new java.io.File(file.project.locationURI)
		
		val output = new java.io.File(projectRoot, 'src-gen/output.structure')
		println(output.absolutePath)
		
		val export = new DescompExport
		export.uploadSimulator(URI.createFileURI(output.absolutePath))
	}
	
	override launch(IEditorPart editor, String mode) {
		//TODO: do sth useful
	}
	
}