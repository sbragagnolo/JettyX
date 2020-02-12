Class {
	#name : #JXProtoObject,
	#superclass : #Object,
	#instVars : [
		'__id',
		'__class',
		'__serialization'
	],
	#category : #JettyX
}

{ #category : #accessing }
JXProtoObject >> extendedStoreAt: aPropertyName put: aValue [
	self subclassResponsibility 
]

{ #category : #accessing }
JXProtoObject >> storeAt: aPropertyName put: aValue [
	aPropertyName = '__class'
		ifTrue: [ __class := aValue.
			^ self ].
	aPropertyName = '__id'
		ifTrue: [ __id := aValue.
			^ self ].
	aPropertyName = '__serialization'
		ifTrue: [ __serialization := aValue.
			^ self ].
	^ self extendedStoreAt: aPropertyName put: aValue
]
