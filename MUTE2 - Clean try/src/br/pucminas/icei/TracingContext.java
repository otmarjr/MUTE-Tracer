package br.pucminas.icei;

import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

public class TracingContext {
	
	String tracedClassName = "";
	Set<String> tracedFiles = new HashSet<String>();
	
	public void setTracedClassName(String className){
		this.tracedClassName = className;
	}
	
	String getTracedClassName() {
		return tracedClassName;
	}
	
	String getOutputDir() {
		return "C:\\windows\\temp\\mute_log\\";
	}
	
	
	List<String> getIgnoredNames() {
		String ignoredNames = System.getProperty("ignored.names");
		
		if (ignoredNames != null && ignoredNames != ""){
			return Arrays.asList(ignoredNames.split(","));
		}
		
		return new LinkedList<String>();
		
	}
	
	private String getFullTracePath() {
		return getOutputDir() + this.getTracedClassName() + "_client_calls_trace.txt";
	}
	
	private void clearCurrentTraceFile() {
		File trace = new File(getFullTracePath());
		trace.delete();
		System.out.println("===== DELETING FILE " + getFullTracePath());
		
	}
	public void write(String text, String fromClassName) throws IOException {
		if (!tracedFiles.contains(fromClassName)){
			setTracedClassName(fromClassName);
			clearCurrentTraceFile();
			tracedFiles.add(fromClassName);
		}
		
		String path = getFullTracePath();
		PrintWriter out = new PrintWriter(new FileWriter(path, true),true);
		out.write(text);
	    out.close();
	    
	    System.out.println("===== WRITING MESSAGE TO FILE " + getFullTracePath() + "message: " + text);
	}
	
	
}
