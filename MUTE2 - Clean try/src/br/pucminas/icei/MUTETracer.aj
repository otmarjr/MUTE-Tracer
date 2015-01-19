package br.pucminas.icei;

import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Stack;



import org.aspectj.lang.Signature;
import org.omg.PortableServer.CurrentOperations;

public aspect MUTETracer {
	List<String> currentSequence = new LinkedList<String>();

	TracingContext context;
	Map<Object, Object> currentInstantiationContext;
	Stack<String> clientMethodStack = new Stack<String>();
	Stack<Map<Object,Object>> instantiationContextStack = new Stack<Map<Object,Object>>();
	boolean isFirstCall = true;
	
    private TracingContext getContext() {
    		if (context == null){
    			context = new TracingContext();
    		}
    		return context;
    }
    
    private String getTracedCallerName() {
    		String fullName = getContext().getTracedClassName();
    		if (fullName.contains(".")){
    			String[] parts = fullName.split(".");
    			return parts[parts.length-1];
    		}
    		return fullName;
    }
    
    private boolean invocationComingFromHotspot(String callerClassName){
    	return null != callerClassName && callerClassName.endsWith(getTracedCallerName());	
    }
    
    private boolean invokedMethodNotInIgnoredPackage(Signature invokedSignature){
    	if (invokedSignature != null){
    		final String declaringTypeName = invokedSignature.getDeclaringTypeName();
    		
    		for (String igSig : context.getIgnoredNames()){
    			if (declaringTypeName.startsWith(igSig))
    				return false;
    		}
        	
    		return true;
    	} 
    	
    	return false;
    }
    
    
    pointcut anyClientMethod() :
    	(
    	   execution (* *..*(..))
    			&& 
		!cflow(within(MUTETracer))
		);
    
    
    before() : anyClientMethod() {
    	getContext().setTracedClassName(thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getName());
    	String sourceName = thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
    	if (invocationComingFromHotspot(sourceName)){
    		if (currentInstantiationContext != null){
    			instantiationContextStack.push(currentInstantiationContext);
    		}
    		currentInstantiationContext = new HashMap<Object, Object>();
    	}
    }
    
    after() : anyClientMethod() {
    	getContext().setTracedClassName(thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getName());
    	String sourceName = thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
    	if (invocationComingFromHotspot(sourceName)){
    		currentInstantiationContext = instantiationContextStack.isEmpty() ? null : instantiationContextStack.pop();
    	}
    }
    
	pointcut jdkCall() :
        (call (* java..*.*(..)) && !cflow(within(MUTETracer)));
    
    pointcut jdkConstructor () :
    	(call (* ..*.new(..))&& !cflow(within(MUTETracer)));
    
    
    before() : jdkCall(){
    	Object instance = thisJoinPoint.getTarget();
    	if (instance!=null){
    		if (instance.getClass() != null)
    			currentInstantiationContext.putIfAbsent(instance.getClass(), instance);
    	}
    }
    
    after() : jdkCall() {
    	
        Signature sig = thisJoinPointStaticPart.getSignature();
        String sourceName = thisJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
        
        if (invocationComingFromHotspot(sourceName)){
        	if (invokedMethodNotInIgnoredPackage(sig)){
        		Object instance = thisJoinPoint.getTarget();
        		boolean isInstanceMethod = instance != null;
        		
        		boolean firstInstanceBeingTracked = false;
        		
        		if (isInstanceMethod && instance.getClass() != null && currentInstantiationContext.get(instance.getClass()) != null){
        			firstInstanceBeingTracked = currentInstantiationContext.get(instance.getClass()).equals(instance);
        		}
        		
        		if (firstInstanceBeingTracked || !isInstanceMethod){
        			String delimiter = "";
                	
                	if (isFirstCall){
                		delimiter = "";
                		isFirstCall = false;
                	}
                	else{
                		delimiter = ";";
                	}
                	
                	String message = delimiter+sig.getDeclaringTypeName() + "." + sig.toString();
	        		
	        		try {
						getContext().write(message,thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getName());
					} catch (IOException e) {
						e.printStackTrace();
						System.out.println(message);
					}	
        		}
        	}
        	
        }
    }
    
    after() returning(Object instance) : jdkConstructor() {
    	Signature sig = thisJoinPointStaticPart.getSignature();
        String sourceName = thisJoinPointStaticPart.getSourceLocation().getWithinType().getCanonicalName();
        if (invocationComingFromHotspot(sourceName)){
        	String delimiter = "";
        	
        	if (isFirstCall){
        		delimiter = "";
        		isFirstCall = false;
        	}
        	else{
        		delimiter = ";";
        	}
        	
        	String message = delimiter+"new " + sig.getDeclaringTypeName() + "." + sig.toString();
        	if (instance!=null){
        		if (instance.getClass() != null){
        			currentInstantiationContext.putIfAbsent(instance.getClass(), instance);
        		}
        	}
        	
        	if (invokedMethodNotInIgnoredPackage(sig) && instance.getClass() != null && currentInstantiationContext.get(instance.getClass()).equals(instance)){
        		try {
        			getContext().write(message,thisEnclosingJoinPointStaticPart.getSourceLocation().getWithinType().getName());
				} catch (IOException e) {
					e.printStackTrace();
					System.out.println(message);
				}	
        	}
        	
        }
    }
}
