package br.pucminas.icei;

import java.io.Closeable;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

public class TracingContext implements Closeable {
	
	String getTracedClassName() {
		String tracedClassname = System.getProperty("traced.class");
		
		if (tracedClassname == null || tracedClassname == ""){
			throw new RuntimeException("You must suply the caller class name via D-traced.class=<name> argument");
		}
		
		return tracedClassname;
	}
	
	String getOutputDir() {
		
		String outputTraceDir = System.getProperty("trace.output.dir");
		
		if (outputTraceDir == null || outputTraceDir == ""){
			return System.getProperty("java.io.tmpdir");
		}
		
		return outputTraceDir + "/" + getTracedClassName() + "_client_calls_trace.txt";
	}
	
	// Used when a container class controls the execution but you do not want to get its events, like in jtreg's I18NResourceBundle class.
	List<String> getWrapperPackages() {
		String wrapperPackages = System.getProperty("wrapper.packages");
		
		if (wrapperPackages != null && wrapperPackages != ""){
			return Arrays.asList(wrapperPackages.split(","));
		}
		
		return new LinkedList<String>();
	}
	
	List<String> getIgnoredNames() {
		String ignoredNames = System.getProperty("ignored.names");
		
		if (ignoredNames != null && ignoredNames != ""){
			return Arrays.asList(ignoredNames.split(","));
		}
		
		return new LinkedList<String>();
		
	}
	
	FileWriter log = null;
	String outputPath;
	
	public TracingContext() throws IOException{
		outputPath = getOutputDir();
		log = new FileWriter(outputPath);
	}

	public void write(String text) throws IOException {
		log.write(text);
		log.flush();
	}
	
	@Override
	public void close() throws IOException {
		if (log != null){
			log.close();
		}
	}
	
	
}
