package io.opencaesar.oml.validate;

import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.Diagnostician;
import org.eclipse.emf.ecore.util.EcoreUtil;

import io.opencaesar.oml.Member;
import io.opencaesar.oml.Ontology;
import io.opencaesar.oml.util.OmlRead;

public class OmlValidator {

	public static void validate(Ontology ontology) {
		final Diagnostician diagnostician = new Diagnostician() {
			@Override
			public String getObjectLabel(EObject eObject) {
			    final String name;
			    if (eObject instanceof Member) {
			    	name = OmlRead.getAbbreviatedIri(((Member)eObject));
			    } else if (eObject instanceof Ontology) {
			    	name = ((Ontology)eObject).getIri();
			    } else {
			    	name = EcoreUtil.getID(eObject);
			    }
			    return eObject.eClass().getName()+" "+name;
			}
		};
		
		final Diagnostic diagnostic = diagnostician.validate(ontology);
		if (diagnostic.getSeverity() == Diagnostic.ERROR) {
	        final StringBuilder sb = new StringBuilder ( diagnostic.getMessage() );
	        for (final Diagnostic child : diagnostic.getChildren()) {
	            if (child.getSeverity () == Diagnostic.ERROR) {
	                sb.append ( System.lineSeparator () );
	                sb.append ( child.getMessage () );
	            }
	        }
	        throw new IllegalStateException (sb.toString());
		}
	}

}
