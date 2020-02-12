Class {
	#name : #JXCollection,
	#superclass : #JXProtoObject,
	#instVars : [
		'__collection'
	],
	#category : #JettyX
}

{ #category : #adding }
JXCollection >> add: anObject [ 	
	__collection add: anObject 
]

{ #category : #adding }
JXCollection >> initialize [
	super initialize.
	__collection := OrderedCollection new. 
]
