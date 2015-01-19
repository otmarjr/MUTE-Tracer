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
		String systemTempDir = System.getProperty("java.io.tmpdir");
		String muteDir = systemTempDir + "/mute_log/";
		
		File tempDir = new File(muteDir);
		
		if (!tempDir.exists()){
			tempDir.mkdir();
		}
		return tempDir.getAbsolutePath();
	}
	
	
	List<String> getIgnoredNames() {
		return new LinkedList<String>() {{add("java.util.Enumeration"); add("java.io.PrintStream");}};
		
	}
	
	private String getFullTracePath() {
		return getOutputDir() + File.separator + this.getTracedClassName() + "_client_calls_trace.txt";
	}
	
	private void clearCurrentTraceFile() {
		File trace = new File(getFullTracePath());
		trace.delete();
		
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
	    System.out.println("===> Written '" + text + "' to file " + path);
	}
	
	
}
