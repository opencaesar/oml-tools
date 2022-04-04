/**
 * 
 * Copyright 2019-2021 California Institute of Technology ("Caltech").
 * U.S. Government sponsorship acknowledged.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 */
package io.opencaesar.oml.validate;

import java.util.List;

import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.util.Diagnostician;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.EcoreUtil2;

import io.opencaesar.oml.Member;
import io.opencaesar.oml.Ontology;
import io.opencaesar.oml.Reference;
import io.opencaesar.oml.util.OmlRead;

public class OmlValidator {

	public static void validate(Ontology ontology) {
		final Diagnostician diagnostician = new Diagnostician() {
			@Override
			public String getObjectLabel(EObject eObject) {
				String type = eObject.eClass().getName();
				String name = getName(eObject);
			    return type + (name.length()>0 ? " "+name : "");
			}
			private String getName(EObject eObject) {
				if (eObject == null) {
					return "null";
				} else if (eObject.eIsProxy()) {
		    		return ((InternalEObject)eObject).eProxyURI().toString();
		    	} else if (eObject instanceof Member) {
			    	return ((Member)eObject).getAbbreviatedIri();
		    	} else if (eObject instanceof Reference) {
		    		Member member = OmlRead.resolve((Reference)eObject);
		    		if (member == null || member.eIsProxy())
		    			return "";
		    		return "ref/"+getName(member);
			    } else if (eObject instanceof Ontology) {
			    	return ((Ontology)eObject).getPrefix();
			    } else {
			    	EReference eRef = eObject.eContainmentFeature();
			    	int index = -1;
			    	if (eRef.isMany()) {
			    		index = ((List<?>)eObject.eContainer().eGet(eRef)).indexOf(eObject);
			    	}
			    	return getName(eObject.eContainer())+"/"+eRef.getName()+(index != -1 ? "["+index+"]" :"");
			    }
			}
		};
		
		final Diagnostic diagnostic = diagnostician.validate(ontology);
		if (diagnostic.getSeverity() == Diagnostic.ERROR) {
	        final StringBuilder sb = new StringBuilder(diagnostic.getMessage());
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
