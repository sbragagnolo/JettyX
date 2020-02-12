Class {
	#name : #JXReference,
	#superclass : #Object,
	#instVars : [
		'reference',
		'__class'
	],
	#category : #JettyX
}

{ #category : #'as yet unclassified' }
JXReference class >> index: aNumber [
	^ self new
		reference: aNumber asNumber;
		yourself
]

{ #category : #'as yet unclassified' }
JXReference class >> on: aCollection [
	self assert: (aCollection isKindOf: Dictionary).
	^ self new
		reference: aCollection;
		yourself
]

{ #category : #'as yet unclassified' }
JXReference >> isReference [
	^ true 
]

{ #category : #accessing }
JXReference >> reference: aCollection [ 
	reference := aCollection
]
