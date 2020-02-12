Class {
	#name : #JXSet,
	#superclass : #Set,
	#instVars : [
		'__class',
		'__id'
	],
	#category : #JettyX
}

{ #category : #accessing }
JXSet >> storeAt: aPropertyName put: aValue [
	aPropertyName = '__class'
		ifTrue: [ __class := aValue.
			^ self ].
	aPropertyName = '__id'
		ifTrue: [ __id := aValue.
			^ self ].
	self assert: aPropertyName = 'mapping__'.
	self add: (aPropertyName -> aValue).
]
