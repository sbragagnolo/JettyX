Class {
	#name : #JXString,
	#superclass : #JXProtoObject,
	#instVars : [
		'__value'
	],
	#category : #JettyX
}

{ #category : #initialization }
JXString >> setValue: aValue [
	__value := aValue. 
]
