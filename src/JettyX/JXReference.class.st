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

{ #category : #'as yet unclassified' }
JXReference >> refersToClass: aClassName [
 __class := aClassName 
]

{ #category : #'as yet unclassified' }
JXReference >> storeAt: aPropertyName put: aValue [ 
	self assert: aPropertyName = '__class'.
	__class := aValue. 
]
