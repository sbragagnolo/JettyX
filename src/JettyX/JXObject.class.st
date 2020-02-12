Class {
	#name : #JXObject,
	#superclass : #JXProtoObject,
	#instVars : [
		'__properties'
	],
	#category : #JettyX
}

{ #category : #accessing }
JXObject >> extendedStoreAt: aPropertyName put: aValue [
	__properties storeAt: aPropertyName put: aValue
]

{ #category : #accessing }
JXObject >> initialize [
	super initialize. 
	__properties := Dictionary new. 
]
