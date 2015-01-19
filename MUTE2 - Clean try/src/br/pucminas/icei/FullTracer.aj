package br.pucminas.icei;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

public aspect FullTracer {
	pointcut anyClientMethod() :
    	(
    	   execution (* *..*(..))
    			&& 
		!cflow(within(FullTracer))
		    			&& 
		!cflow(within(FullTracer))
		);
	
	pointcut anyCall() :
    	(
    	   call (* *..*(..))
    			&& 
		!cflow(within(FullTracer))
		);
	
	before() : anyClientMethod(){
		try {
		    PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter("c:\\windows\\mute_log\\full_executions.txt", true)));
		    out.println("EXECUTING ====> " + thisJoinPointStaticPart.getSignature().toString());
		    out.close();
		} catch (IOException e) {
		    //exception handling left as an exercise for the reader
			System.out.println("EXECUTING ====> " + thisJoinPointStaticPart.getSignature().toString());
		}
	} 
	
	before() : anyClientMethod(){
		try {
		    PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter("c:\\windows\\mute_log\\full_calls.txt", true)));
		    out.println("CALLING ====> " + thisJoinPointStaticPart.getSignature().toString());
		    out.close();
		} catch (IOException e) {
		    //exception handling left as an exercise for the reader
			System.out.println("CALLING ====> " + thisJoinPointStaticPart.getSignature().toString());
		}
	}
}
