package br.pucminas.icei;

import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Stack;


import java.util.logging.Level;
import java.util.logging.Logger;

import org.aspectj.lang.Signature;

public aspect MUTETracer {
	List<String> currentSequence = new LinkedList<>();
	TracingContext context;
	Map<Object, Object> currentInstantiationContext;
	Stack<String> clientMethodStack = new Stack<>();
	Stack<Map<Object,Object>> instantiationContextStack = new Stack<>();
	boolean firstMessage = true;
    private TracingContext getContext() {
    		if (context == null){
    			 try {
    				 
					context = new TracingContext();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
    		}
    		return context;
    }
    
    private String getTracedCallerName() {
    		String fullName = getContext().getTracedClassName();
    		if (fullName.contains(".")){
    		String[] parts = fullName.split(".");
    		
    		return parts[parts.length-1];
    }return fullName;
    }
    private boolean invocationComingFromHotspot(String callerClassName){
    	return null != callerClassName && (callerClassName.endsWith(getTracedCallerName()) || invocationComingFromWrapperClass(callerClassName)) || true;	
    }
    
    private boolean invocationComingFromWrapperClass(String callerClassName){
    	if (callerClassName == null)
    		return false;
    	else
    		return context.getWrapperPackages().stream().anyMatch(pkg -> pkg != null && callerClassName.startsWith(pkg));
    }
    
    private boolean invokedMethodNotInIgnoredPackage(Signature invokedSignature){
    	if (invokedSignature != null){
    		final String declaringTypeName = invokedSignature.getDeclaringTypeName();
        	return declaringTypeName != null && !context.getIgnoredNames().stream().anyMatch(igSig -> declaringTypeName.startsWith(igSig));
    	} 
    	
    	return false;
    }
    
    private Logger getLogger() {
    	return Logger.getLogger(MUTETracer.class.getName());
    }
    
    private void writeMessage(String message){
    	try {
    		getContext().write(message);
			getLogger().log(Level.FINE, "Writting " + message + " to trace.");
		} catch (IOException e) {
			getLogger().log(Level.SEVERE, "Error while trying to trace message ' " + message + "'.", e);
		}	
	}
    
    pointcut anyClientMethod() :
    	(
    	   execution (* *..*(..))
    			&& 
		!cflow(within(MUTETracer))
		);
    
    before() : anyClientMethod() {
    	String sourceName = thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
    	if (invocationComingFromHotspot(sourceName)){
    		if (currentInstantiationContext != null){
    			getLogger().log(Level.FINE, "Pushing current instantiation context to stack....");
    			instantiationContextStack.push(currentInstantiationContext);
    		}
    		currentInstantiationContext = new HashMap<>();
    	}
    	else{
    		getLogger().log(Level.FINE, "Ignoring client method call...not a hot spot " + sourceName  + " <detected class> != " + context.getTracedClassName() + " <traced class>");
    	}
    }
    
    after() : anyClientMethod() {
    	String sourceName = thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
    	if (invocationComingFromHotspot(sourceName)){
    		if (!instantiationContextStack.isEmpty()){
    			getLogger().log(Level.FINE, "Restoring current instantiation context...");
    		}
    		else{
    			currentInstantiationContext = null;
    			getLogger().log(Level.FINE, "Reseting to null instantiation context...");
    		}
    	}
    }
    
	pointcut jdkCall() :
        (call (* java..*.*(..)) && !cflow(within(MUTETracer)));
    
    pointcut jdkConstructor () :
    	(call (* ..*.new(..))&& !cflow(within(MUTETracer)));
    
    
    before() : jdkCall(){
    	String sourceName = thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
	    	if (invocationComingFromHotspot(sourceName) && invokedMethodNotInIgnoredPackage(thisJoinPointStaticPart.getSignature())){
	    	Object instance = thisJoinPoint.getTarget();
	    	if (instance!=null){
	    		String curentClassName = instance.getClass() == null ? "<NULL CLASS>" : instance.getClass().getName();
    			getLogger().log(Level.FINE, "Putting if absent instance of type " +curentClassName+ "is the first on current context.");
	    		currentInstantiationContext.putIfAbsent(instance.getClass(), instance);
	    	}
    	}
    }
    
    after() : jdkCall() {
    	
        Signature sig = thisJoinPointStaticPart.getSignature();
        String sourceName = thisJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
        getLogger().log(Level.FINER, "After receiving call to " + sig.toString());
        if (invocationComingFromHotspot(sourceName)){
        	if (invokedMethodNotInIgnoredPackage(sig)){
        		
        		Object instance = thisJoinPoint.getTarget();
        		boolean isInstanceMethod = instance != null;
        		
        		boolean firstInstanceBeingTracked = false;
        		
        		if (isInstanceMethod){
        			String curentClassName = instance.getClass() == null ? "<NULL CLASS>" : instance.getClass().getName();
        			
        			getLogger().log(Level.FINEST, "Checking if instance of type " +curentClassName+ "is the first on current context.");
        			if (currentInstantiationContext == null){
        				throw new RuntimeException("Current instantiation context cannot be null. Check your aspect's configuration.");
        			}
        			
        			Object existingInstance = currentInstantiationContext.getOrDefault(instance.getClass(),null);
        			if (existingInstance == null){
        				getLogger().log(Level.SEVERE, "Current instantiation context does not contain instance of type " + curentClassName + ". Check your aspect's configuration.");
        				firstInstanceBeingTracked = true;
        				currentInstantiationContext.put(instance.getClass(), instance);
        			}
        			else{
        				getLogger().log(Level.FINEST, "First instance of type " + curentClassName + " loaded.");
        			}
        			
        			firstInstanceBeingTracked = instance == existingInstance;
        		}
        		
        		getLogger().log(Level.FINER, sourceName + " isFirstInstanceBeingTracked? " + firstInstanceBeingTracked + " instanceMethod? " + isInstanceMethod);
        		if (firstInstanceBeingTracked || !isInstanceMethod){
        			String delimiter = firstMessage ? "" : ",";
                	firstMessage = false;
	        		String message = delimiter + sig.getDeclaringTypeName() + "." + sig.toString();
	        	
	        		if (invokedMethodNotInIgnoredPackage(sig))
	        		{
	        			writeMessage(message);
	        		}
        		}
        	}
        }
    }
    
    
    after() returning(Object instance) : jdkConstructor() {
    	Signature sig = thisJoinPointStaticPart.getSignature();
        String sourceName = thisJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
        getLogger().log(Level.FINER, "After creating new instance of " + sig.toString());
        if (invocationComingFromHotspot(sourceName)){
        	
        	String delimiter = firstMessage ? "" : ",";
        	firstMessage = false;
        	String message = delimiter + "new " + sig.getDeclaringTypeName() + "." + sig.toString();
        	if (instance!=null){
        		currentInstantiationContext.putIfAbsent(instance.getClass(), instance);
        	}
        	
        	if (invokedMethodNotInIgnoredPackage(sig)){
        		writeMessage(message);
        	}
        }
    }
}
