Class {
	#name : #JXReference,
	#superclass : #Object,
	#instVars : [
		'reference'
	],
	#category : #JettyX
}

{ #category : #'as yet unclassified' }
JXReference class >> on: aCollection [
	self assert: (aCollection isKindOf: Dictionary).
	^ self new
		reference: aCollection;
		yourself
]

{ #category : #accessing }
JXReference >> reference: aCollection [ 
	reference := aCollection
]
