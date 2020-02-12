Class {
	#name : #JXAssociation,
	#superclass : #Object,
	#instVars : [
		'mapped'
	],
	#category : #JettyX
}

{ #category : #'as yet unclassified' }
JXAssociation >> initialize [
	super initialize.
	mapped := Dictionary new
]

{ #category : #'as yet unclassified' }
JXAssociation >> map: map type: name [
	mapped at: name put: map .
]
