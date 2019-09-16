package io.github.abelgomez.asyncapi.generator

import io.github.abelgomez.asyncapi.asyncApi.AsyncAPI
import io.github.abelgomez.asyncapi.asyncApi.Reference
import io.github.abelgomez.asyncapi.asyncApi.Topic
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import io.github.abelgomez.asyncapi.asyncApi.AbstractMessage
import io.github.abelgomez.asyncapi.asyncApi.Message
import java.util.Stack
import java.util.List
import io.github.abelgomez.asyncapi.asyncApi.NamedMessage
import io.github.abelgomez.asyncapi.asyncApi.NamedSchema
import io.github.abelgomez.asyncapi.asyncApi.Schema
import io.github.abelgomez.asyncapi.asyncApi.AbstractSchema

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class AsyncApiGenerator extends AbstractGenerator {

	AsyncAPI api;

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		api = resource.contents.findFirst[a | a instanceof AsyncAPI] as AsyncAPI;
		for (t : api.topics) {
			t.messageClasses(fsa)
		}
		for (ns : api.components.schemas) {
			if (!ns.schema.resolve.isBasicType) {
				fsa.generateFile("schemas/" + ns.toJavaType + ".java", ns.namedSchemaClassFile)
			}
		}
		fsa.generateFile("../ivy.xml", generateIvy)
	}
	
	def generateIvy() '''
	<ivy-module version="2.0">
	    <info organisation="com.example" module="mymodule"/>
	    <dependencies>
	        <dependency org="com.google.code.gson" name="gson" rev="2.8.5"/>
	        <dependency org="org.eclipse.paho" name="org.eclipse.paho.client.mqttv3" rev="1.2.1"/>
	    </dependencies>
	</ivy-module>
	'''
	
	def void messageClasses(Topic t, IFileSystemAccess2 fsa) {
		if (t.publish !== null) {
			fsa.generateFile(t.path + "/" + t.publishMessageClassName + ".java", t.publishClass);
		}
		if (t.subscribe !== null) {
			fsa.generateFile(t.path + "/" + t.subscribeMessageClassName + ".java", t.subscribeClass);
		}
	}

	def gsonImports() '''
		import com.google.gson.Gson;
		import com.google.gson.GsonBuilder;
		import com.google.gson.annotations.SerializedName;
	'''

	def mqttImports() '''
        import org.eclipse.paho.client.mqttv3.MqttClient;
        import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
        import org.eclipse.paho.client.mqttv3.MqttException;
        import org.eclipse.paho.client.mqttv3.MqttMessage;
        import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
	'''

	def publishClass(Topic t) '''
		package �t.packageName�;
		
		�IF t.publish.resolve.payload.isNamedSchema�
		import schemas.�t.publishPayloadClassName�;
		�ELSE�
		�gsonImports�
		�ENDIF�
		
		�mqttImports�
		
		/**
		�IF t.publish.summary!== null�
		 * �t.publish.summary�
		�ENDIF�
		�IF t.publish.description!== null�
		 * �t.publish.description�
		�ENDIF�
		 */
		public class �t.publishMessageClassName� {
			/**
			 * Create payload
			 */
			public static final �t.publishPayloadClassName�.�t.publishPayloadClassName�Builder payloadBuilder() {
				return �t.publishPayloadClassName�.�t.publishPayloadClassName�Builder.newBuilder();
			}
			
			public static final void publish(�t.publishPayloadClassName� payload) {
				String topic = "�t.name�";
				int qos = 2;
				String broker = "�api.servers.get(0).url�";
				String clientId = java.util.UUID.randomUUID().toString();
				MemoryPersistence persistence = new MemoryPersistence();
				
				try (MqttClient client = new MqttClient(broker, clientId, persistence);) {
				    
				    MqttConnectOptions connOpts = new MqttConnectOptions();
				    connOpts.setCleanSession(true);
				    
				    MqttMessage message = new MqttMessage(payload.toJson().getBytes());
				    message.setQos(qos);
				    
				    client.connect(connOpts);
				    client.publish(topic, message);
				    client.disconnect();
				    
				} catch(MqttException e) {
					throw new RuntimeException(e);
				}
			}
			
			�IF !t.publish.resolve.payload.isNamedSchema�
			�t.publish.resolve.payload.resolve.unnamedSchemaClass�
			�ENDIF�
		}
	'''

	def subscribeClass(Topic t) '''
		package �t.packageName�;
		
		�IF t.subscribe.resolve.payload.isNamedSchema�
		import schemas.�t.subscribePayloadClassName�;
		�ELSE�
		�gsonImports�
		�ENDIF�
		
		/**
		�IF t.subscribe.summary!== null�
		 * �t.subscribe.summary�
		�ENDIF�
		�IF t.subscribe.description!== null�
		 * �t.subscribe.description�
		�ENDIF�
		 */
		public class �t.subscribeMessageClassName� {
			/**
			 * Create payload
			 */
			public static final �t.subscribePayloadClassName�.�t.subscribePayloadClassName�Builder payloadBuilder() {
				return �t.subscribePayloadClassName�.�t.subscribePayloadClassName�Builder.newBuilder();
			}
			
			�IF !t.subscribe.resolve.payload.isNamedSchema�
			�t.subscribe.resolve.payload.resolve.unnamedSchemaClass�
			�ENDIF�
		}
	'''
	
	def summary(AbstractMessage m) {
		return m.resolve.summary;
	}
	
	def description(AbstractMessage m) {
		return m.resolve.description;
	}
	
	def namedSchemaClassFile(NamedSchema ns) '''
		package schemas;
		
		�gsonImports�
		
		�ns.namedSchemaClass�
	'''
	
	def String namedSchemaClass(NamedSchema ns) '''
		/**
		�IF ns.title !== null�
		 * �ns.title�
		�ENDIF�
		�IF ns.description !== null�
		 * �ns.description�
		�ENDIF�
		 */
		public �IF ns.eContainer instanceof Schema�static �ENDIF�class �ns.toJavaType� implements Cloneable {
			�ns.schema.resolve.schemaClassBody(ns.toJavaType)�
		}
		
	'''
	
	def String unnamedSchemaClass(Schema s) '''
		/**
		�IF s.title !== null�
		 * �s.title�
		�ENDIF�
		�IF s.description !== null�
		 * �s.description�
		�ENDIF�
		 */
		public static class Payload {
			�s.schemaClassBody("Payload")�
		}
		
	'''

	def String schemaClassBody(Schema s, String thisTypeName) '''
		�FOR p : s.properties.filter[p | p.schema.resolve.enumType]�
			�p.namedSchemaEnum�
		�ENDFOR�
		�FOR p : s.properties.filter[p | p.schema.resolve.objectType]�
			�p.namedSchemaClass�
		�ENDFOR�
		�FOR p : s.properties�
			�p.namedSchemaField�
		�ENDFOR�

			
		private �thisTypeName�() {
		}
			
		public static final �thisTypeName�Builder newBuilder() {
			return new �thisTypeName�Builder();
		}
		
		public String toJson() {
			return toJson(false);
		}

		public String toJson(boolean pretty) {
			Gson gson = pretty ? new GsonBuilder().setPrettyPrinting().create() : new Gson();
			return gson.toJson(this);
		}
		
		public static �thisTypeName� fromJson(String json) {
			Gson gson = new Gson();
			return gson.fromJson(json, �thisTypeName�.class);
		}
		
		protected Object clone() throws CloneNotSupportedException {
			�thisTypeName� clone = new �thisTypeName�();
			�FOR p : s.properties.filter[p | !p.schema.resolve.objectType]�
			clone.�p.friendlyName.asJavaIdentifier� = this.�p.friendlyName.asJavaIdentifier�;
			�ENDFOR�
			�FOR p : s.properties.filter[p | p.schema.resolve.objectType]�
			clone.�p.friendlyName.asJavaIdentifier� = (�p.toJavaType�) this.�p.friendlyName.asJavaIdentifier�.clone();
			�ENDFOR�
			return clone;
		}
		
		public static class �thisTypeName�Builder {
			
			private �thisTypeName� instance = new �thisTypeName�();
			
			public static �thisTypeName�Builder newBuilder() {
				return new �thisTypeName�Builder();
			}
			
			�FOR p : s.properties�
				�p.namedSchemaMethod(thisTypeName)�
			�ENDFOR�
			
			public �thisTypeName� build() {
				try {
					return (�thisTypeName�) instance.clone();
				} catch (CloneNotSupportedException e) {
					throw new RuntimeException("Unable to build: " + this, e);
				}
			}
		}
	'''

	def namedSchemaEnum(NamedSchema ns) '''
		/**
		�IF ns.title !== null�
		 * �ns.title�
		�ENDIF�
		�IF ns.description !== null�
		 * �ns.description�
		�ENDIF�
		 */
		public enum �ns.toJavaType� {
			�ns.enum_.join(", ")�;
		}
		
	'''

	def namedSchemaField(NamedSchema ns) '''
		/**
		 * �ns.title�
		�IF ns.description !== null�
		 * �ns.description�
		�ENDIF�
		 */
		@SerializedName("�ns.name�")
		private �ns.toJavaType� �ns.friendlyName.asJavaIdentifier�;
		
	'''

	def namedSchemaMethod(NamedSchema ns, String thisTypeName) '''
		public �thisTypeName�Builder with�ns.friendlyName�(�ns.toJavaType� �ns.friendlyName.asJavaIdentifier�) {
			this.instance.�ns.friendlyName.asJavaIdentifier� = �ns.friendlyName.asJavaIdentifier�;
			return this;
		}
		
	'''

	def title(NamedSchema ns) {
		return ns.schema.resolve.title;
	}	

	def description(NamedSchema ns) {
		return ns.schema.resolve.description;
	}
	
	def enum_(NamedSchema ns) {
		return ns.schema.resolve.enum.map[e | e.replaceAll("\"", "").asJavaClassName];
	}

	def friendlyName(NamedSchema ns) {
		return (if (ns.schema.resolve.friendlyName !== null) ns.schema.resolve.friendlyName else ns.name).asJavaClassName; 
	}
	
	def String publishMessageClassName(Topic t) {
		val m = t.publish;
		if (m === null) {
			throw new RuntimeException("Unexpected type of publish Message: " + m);
		} else if (m.isNamedMessage) {
			return m.name.asJavaClassName
		} else {
			return "Publish";
		}
	}

	def String publishPayloadClassName(Topic t) {
		if (t.publish.resolve.payload.isNamedSchema) {
			return t.publish.resolve.payload.name.asJavaClassName
		} else {
			return "Payload"
		}
	}
	
	def String subscribeMessageClassName(Topic t) {
		val m = t.subscribe;
		if (m === null) {
			throw new RuntimeException("Unexpected type of subscribe Message: " + m);
		} else if (m.isNamedMessage) {
			return m.name.asJavaClassName
		} else {
			return "Subscribe";
		}
	}

	def String subscribePayloadClassName(Topic t) {
		if (t.subscribe.resolve.payload.isNamedSchema) {
			return t.subscribe.resolve.payload.name.asJavaClassName;
		} else {
			return "Payload";
		}
	}
	
	def isNamedMessage(AbstractMessage am) {
		return (am instanceof Reference);
	}

	def isNamedSchema(AbstractSchema s) {
		return (s instanceof Reference);
	}

	def name(AbstractMessage am) {
		if (am instanceof Reference) {
			return ((am as Reference).resolve as NamedMessage).name;
		} else {
			throw new RuntimeException("Unexpected type of Message (expecting a Reference): " + am);
		}
	}
	
	def name(AbstractSchema s) {
		if (s instanceof Reference) {
			return ((s as Reference).resolve as NamedSchema).name;
		} else {
			throw new RuntimeException("Unexpected type of Schema (expecting a Reference): " + s);
		}
	}
	
	def String packageName(Topic t) {
		var segments = ((if (api.baseTopic !== null) api.baseTopic else "") + t.name).split("/");
		if (segments.exists[s | s.length == 0]) {
			throw new RuntimeException("Empty segment in package name derived from: " + segments);
		} 
		return segments.map[s | s.asJavaIdentifier].join(".");
	}
	
	def String path(Topic t) {
		return t.packageName.replaceAll("\\.", "/") ;
	}

	def String asJavaIdentifier(String s) {
		val builder = new StringBuilder();
		var nextUpper = false;
		for (char c : s.toCharArray) {
			if (Character.isDigit(c)) {
				builder.append(c);
			} else if (Character.isAlphabetic(c)) {
				if (nextUpper) {
					builder.append(Character.toUpperCase(c));
					nextUpper = false;
				} else {
					builder.append(c);
				}
			} else if (c == Character.valueOf('-') || c == Character.valueOf('_')) {
				nextUpper = true;
			} else {
				builder.append("_");
			}
		}
		val retVal = builder.toString()
		return if (!Character.isLowerCase(retVal.charAt(0))) "_" + retVal else retVal;	
	}

	def String asJavaClassName(String s) {
		val builder = new StringBuilder();
		var nextUpper = true;
		for (char c : s.toCharArray) {
			if (Character.isDigit(c)) {
				builder.append(c);
				nextUpper = true;
			} else if (Character.isAlphabetic(c)) {
				if (nextUpper) {
					builder.append(Character.toUpperCase(c));
					nextUpper = false;
				} else {
					builder.append(c);
				}
			} else if (c == Character.valueOf('-') || c == Character.valueOf('_')) {
				nextUpper = true;
			} else {
				nextUpper = true;
				builder.append("_");
			}
		}
		val retVal = builder.toString()
		return if (Character.isDigit(retVal.charAt(0))) "_" + retVal else retVal;	
	}
	
	def Message resolve(AbstractMessage m) {
		if (m instanceof Message) {
			return m;
		} else if (m instanceof Reference) {
			return (m.resolve as NamedMessage).message.resolve;
		} else {
			throw new RuntimeException("Unexpected abstract message: " + m);
		}
	}
	
	def Schema resolve(AbstractSchema s) {
		if (s instanceof Schema) {
			return s;
		} else if (s instanceof Reference) {
			return (s.resolve as NamedSchema).schema.resolve;
		} else {
			throw new RuntimeException("Unexpected abstract schema: " + s);
		}
	}
	
	
	def EObject resolve(Reference r) {
		var stack = new Stack();
		stack.addAll(r.uri.split("/").reverse);
		if (stack.pop != "#") {
			throw new RuntimeException("Only relative references allowed: " + r.uri);
		}
		var elt = api as EObject;
		while (!stack.isEmpty) {
			val eClass = elt.eClass;
			val featureName = stack.pop;
			var featureValue = elt.eGet(eClass.EAllReferences.findFirst[ref | ref.name == featureName]);
			if (featureValue instanceof EObject) {
				elt = featureValue as EObject;
			} else if (featureValue instanceof List) {
				val list = featureValue as List<EObject>;
				val eltName = stack.pop;
				elt = list.findFirst[eo | eo.eGet(eo.eClass.EAllAttributes.findFirst[at | at.name == "name"]) == eltName]
			} else {
				throw new RuntimeException("Unexpected feature value: " + featureValue);
			}
		}
		if (elt === null) {
			throw new RuntimeException("Unable to resolve Reference: " + r);
		} else {
			return elt;
		}
	}

	def toJavaType(NamedSchema s) {
		val schema = s.schema.resolve;
//		if (schema.type === null) {
//			throw new RuntimeException("Unexpected JSON type (null) for NamedSchema: " + s);
//		} else 
		if (schema.objectType || schema.enumType) {
			if (schema.friendlyName !== null) {
				return schema.friendlyName.asJavaClassName;
			} else {
				return s.name.asJavaClassName;
			}
		} else {
			switch (schema.type.toLowerCase) {
				case "string": {
					return "String";
				}
				case "number": {
					return "Double";
				}
				case "integer": {
					return "Integer";
				}
				case "boolean": {
					return "Boolean";
				}
				case "null": {
					return "Object";
				}
				case "any": {
					return "Object";
				}
				case "array": {
					return "java.util.List";
				}
			}
		}
	}

	def isObjectType(Schema s) {
		if (s.type == "object") {
			return true;
		} else if (!s.properties.isEmpty) {
			return true;
		} else {
			return false;
		}
	}
	
	def isEnumType(Schema s) {
		if (!s.enum.empty) {
			return true;
		} else {
			return false;
		}
	}

	def isBasicType(Schema s) {
		if (s.isObjectType) {
			return false;
		} else if (s !== null) {
			switch (s.type.toLowerCase) {
				case "string": {
					return true;
				}
				case "number": {
					return true;
				}
				case "integer": {
					return true;
				}
				case "boolean": {
					return true;
				}
				case "null": {
					return true;
				}
				case "any": {
					return true;
				}
				case "array": {
					return true;
				}
			}
		} 
		return false;
	}
}