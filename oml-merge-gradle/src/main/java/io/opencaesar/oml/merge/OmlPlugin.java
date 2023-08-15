package io.opencaesar.oml.merge;

import org.gradle.api.Plugin;
import org.gradle.api.Project;

/**
 * The OML plugin create the minimum Gradle configurations needed 
 */
public class OmlPlugin implements Plugin<Project>  {
	
	private static final String OML_CONFIGURATION = "oml";
	private static final String DEFAULT_CONFIGURATION = "default";
	
	/**
	 * default constructor
	 */
	public OmlPlugin() {}

	@Override
	public void apply(Project project) {
		var oml = project.getConfigurations().findByName(OML_CONFIGURATION);
		if (oml == null) {
			oml = project.getConfigurations().create(OML_CONFIGURATION);
		}
		var _default = project.getConfigurations().findByName(DEFAULT_CONFIGURATION);
		if (_default == null) {
			_default = project.getConfigurations().create(DEFAULT_CONFIGURATION);
		}
		if (!_default.getExtendsFrom().contains(oml)) {
			_default.extendsFrom(oml);
		}
	}

}
