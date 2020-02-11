Class {
	#name : #JXArray,
	#superclass : #Object,
	#instVars : [
		'entries'
	],
	#category : #JettyX
}

{ #category : #'as yet unclassified' }
JXArray >> addAll: aCollection [ 
	entries addAll: aCollection 
]

{ #category : #adding }
JXArray >> addAssociation: anAssociation [ 
	entries add: anAssociation 
]

{ #category : #adding }
JXArray >> initialize [
	super initialize.
	entries := OrderedCollection new
]
