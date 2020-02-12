Class {
	#name : #JXInt,
	#superclass : #JXProtoObject,
	#instVars : [
		'__value'
	],
	#category : #JettyX
}

{ #category : #initialization }
JXInt >> setValue: aValue [
	__value := aValue. 
]
