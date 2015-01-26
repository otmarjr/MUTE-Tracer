package br.pucminas.icei;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.security.CodeSource;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import org.aspectj.lang.reflect.SourceLocation;
import org.omg.CORBA.portable.InputStream;

public class TracingContext {
	
	String tracedClassName = "";
	Set<String> tracedFiles = new HashSet<String>();
	
	public void setTracedClassName(String className){
		this.tracedClassName = className;
	}
	
	String getTracedClassName() {
		return tracedClassName;
	}
	
	SourceLocation sourceLoc;
	
	public void setSourceLocation(SourceLocation sl) {
		this.sourceLoc = sl;
	}
	
	File getPropertiesFile() {
			return new File(System.getenv("TMP"), "mute_weaving.properties");
	}
	
	File propertiesFile;
	
	Map<String, String> getWeavingProperties(){
		Map<String, String> props = new HashMap<String, String>();

		//for (String k : System.getenv().keySet()){
		FileInputStream fis = null;
		
		try {
			fis = new FileInputStream(getPropertiesFile());
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		 
		//Construct BufferedReader from InputStreamReader
		BufferedReader br = new BufferedReader(new InputStreamReader(fis));
	 
		String line = null;
		try {
			while ((line = br.readLine()) != null) {
				if (line.indexOf("=") >= 0){
					String[] parts = line.split("=");
					props.put(parts[0], parts[1]);
				}
			}
			br.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	 
		return props;
	}
	
	
	String getOutputDir() {
		String systemTempDir = System.getProperty("java.io.tmpdir");
		String muteDir = systemTempDir + "/mute_log/";
		String JavaPackageDir = new File(getWeavingProperties().get("original.source.code.location")).getParent();
		
		if (JavaPackageDir != null){
			JavaPackageDir = JavaPackageDir.substring(JavaPackageDir.indexOf("java"));
		}
		
		
		File tempDir = new File(muteDir,JavaPackageDir);
		//File tempDir = new File(muteDir);
		
		if (!tempDir.exists()){
			System.out.println("Does not exist!");
			tempDir.mkdirs();
		}
		System.out.println("Absolute path for temp files: " + tempDir.getAbsolutePath());
		return tempDir.getAbsolutePath();
	}
	
	
	List<String> getIgnoredNames() {
		return new LinkedList<String>() {{add("java.util.Enumeration"); add("java.io.PrintStream"); add("java.lang");}};
		
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
	}
	
	
}
