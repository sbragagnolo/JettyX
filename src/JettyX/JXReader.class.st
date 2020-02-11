Class {
	#name : #JXReader,
	#superclass : #Object,
	#instVars : [
		'objectRegistry',
		'classRegistry',
		'references',
		'emptyObject'
	],
	#category : #JettyX
}

{ #category : #'as yet unclassified' }
JXReader >> classSymbolNameFor: aClassName [
	| name |
	name := ('.' split: aClassName) last copyReplaceAll: 'Impl' with: ''.
	^( 'VB6' , name capitalized) asSymbol 
]

{ #category : #'as yet unclassified' }
JXReader >> commonSuperClass [
	^ Object
]

{ #category : #'as yet unclassified' }
JXReader >> emptyObject [
	^ emptyObject ifNil: [ emptyObject := Object new ]
]

{ #category : #'as yet unclassified' }
JXReader >> findClassByName: aClassName ifNone: aBlockClosure [
	^ (self isWellKnownClass: aClassName)
		ifTrue: [ self resolveWellKnownClass: aClassName ]
		ifFalse: [ classRegistry at: aClassName ifAbsent: [ aBlockClosure value ] ]
]

{ #category : #'as yet unclassified' }
JXReader >> findObjectId: anId ifNone: aBlockClosure [
	^ objectRegistry at: anId ifAbsent: [ aBlockClosure value ]
]

{ #category : #'as yet unclassified' }
JXReader >> initialize [
	super initialize.
	objectRegistry := Dictionary new.
	classRegistry := Dictionary new
]

{ #category : #'as yet unclassified' }
JXReader >> installClassNamed: aClassName [
	(self class environment
		includesKey: (self classSymbolNameFor: aClassName))
		ifTrue: [ self halt ].
	^ self commonSuperClass
		subclass: (self classSymbolNameFor: aClassName)
		instanceVariableNames: ''
		classVariableNames: ''
		package: self targetPackage
]

{ #category : #'as yet unclassified' }
JXReader >> installObject: anObject onId: anInteger [
	objectRegistry at: anInteger put: anObject.
	^ anObject
]

{ #category : #'as yet unclassified' }
JXReader >> instantiate: aClassName [
	^ (self
		findClassByName: aClassName
		ifNone: [ self installClassNamed: aClassName ]) new
]

{ #category : #'as yet unclassified' }
JXReader >> isEmptyObject: aCollection [
	^ (aCollection isKindOf: Dictionary)
		and: [ aCollection size = 1 and: [ aCollection includesKey: '@id' ] ]
]

{ #category : #'as yet unclassified' }
JXReader >> isEnumReference: aCollection [
	^ (aCollection includesKey: '@class')
		and: [ aCollection includesKey: '$' ]
]

{ #category : #'as yet unclassified' }
JXReader >> isMetaAssociation: anAssociation [
	^ {'@id' . '@class'} includes: anAssociation key
]

{ #category : #'as yet unclassified' }
JXReader >> isObjectDefinition: aDictionary [
	^ (aDictionary isKindOf: Dictionary)
		and: [ (aDictionary includesKey: '@id')
				and: [ aDictionary includesKey: '@class' ] ]
]

{ #category : #'as yet unclassified' }
JXReader >> isObjectReference: aDictionary [
	^ ((aDictionary isKindOf: Dictionary)
		and: [ aDictionary size = 2
				and: [ | classname |
					classname := aDictionary keys
						detect: [ :k | self isPossibleClassName: k ]
						ifNone: [ nil ].
					(classname isNil
						and: [ (aDictionary includesKey: '@class')
								and: [ aDictionary includesKey: '@reference' ] ])
						ifTrue: [ ^ true ].
					classname isNotNil
						and: [ | sub |
							sub := aDictionary at: classname.
							sub isDictionary and: [ sub includesKey: '@reference' ] ] ] ]) or: [ aDictionary includesKey: '@reference'  ]
]

{ #category : #'as yet unclassified' }
JXReader >> isPossibleClassName: aName [
	^ (aName includesSubstring: '.') or: [ aName = 'linked-hash-map' ]
]

{ #category : #testing }
JXReader >> isWellKnownClass: aClassName [
	^ (aClassName indexOf: $.) = 0
]

{ #category : #accessing }
JXReader >> map: aStream to: anOtherStream [
	[ aStream atEnd ]
		whileFalse: [ anOtherStream nextPut: (self process: aStream next) ]
]

{ #category : #accessing }
JXReader >> object: anObjectId ofClass: aClassName [
	^ self
		findObjectId: anObjectId asInteger
		ifNone: [ | instance |
			instance := self instantiate: aClassName.
			self installObject: instance onId: anObjectId asNumber ]
]

{ #category : #accessing }
JXReader >> process: aParsedObject [
	^ aParsedObject beProcessedBy: self
]

{ #category : #'as yet unclassified' }
JXReader >> processArray: anArray [
	| typeSelector |
	(anArray size = 1
		and: [ (anArray first includesKey: '@id')
				and: [ anArray first includesKey: 'entry' ] ])
		ifTrue: [ | val relatedDictArray |
			relatedDictArray := (anArray first at: #entry) isDictionary
				ifTrue: [ {(anArray first at: #entry)} ]
				ifFalse: [ anArray first at: #entry ].
			val := (relatedDictArray first keys reject: [ :k | k = 'string' ])
				first.
			^ relatedDictArray
				collect: [ :c | 
					| aval |
					c isDictionary
						ifFalse: [ self halt ].
					aval := (c at: val) isDictionary
						ifTrue: [ {(c at: val)} ]
						ifFalse: [ c at: val ].
					aval do: [ :each | each at: '@class' put: val ].
					(c at: 'string') -> (self process: aval) ] ]
		ifFalse: [ (anArray size = 1 and: [ anArray first includesKey: '@id' ])
				ifTrue: [ anArray first at: '@class' put: 'array'.
					^ self process: anArray first ] ].
	(anArray size = 1
		and: [ (anArray first includesKey: '@id')
				and: [ anArray first size = 2
						and: [ typeSelector := (anArray first keys reject: [ :k | k = '@id' ])
								first.
							(anArray first at: typeSelector) isKindOf: Array ] ] ])
		ifTrue: [ | val |
			^ (anArray first at: typeSelector)
				collect: [ :c | 
					c at: '@class' put: typeSelector.
					self process: c ] ].
	^ anArray collect: [ :x | self process: x ]
]

{ #category : #'as yet unclassified' }
JXReader >> processBoolean: aTrue [ 
	^ aTrue 
]

{ #category : #'as yet unclassified' }
JXReader >> processDictionary: aDictionary [
	| relatedObject |
	(self isObjectDefinition: aDictionary)
		ifTrue: [ relatedObject := self processObjectDefinition: aDictionary ]
		ifFalse: [ (self isEmptyObject: aDictionary)
				ifTrue: [ relatedObject := self processEmptyObject: aDictionary ]
				ifFalse: [ (self isObjectReference: aDictionary)
						ifTrue: [ relatedObject := self processReference: aDictionary ]
						ifFalse: [ (self isEnumReference: aDictionary)
								ifTrue: [ relatedObject := self processEnumReference: aDictionary ]
								ifFalse: [ self halt ] ] ] ].
	^ relatedObject
]

{ #category : #'as yet unclassified' }
JXReader >> processEmptyObject: aCollection [
	^ objectRegistry
		at: (aCollection at: '@id') asNumber
		ifAbsentPut: [ self emptyObject ]
]

{ #category : #'as yet unclassified' }
JXReader >> processEnumReference: aCollection [
	^ references
		at: aCollection
		ifAbsentPut: [ JXEnumReference new
				reference: aCollection;
				yourself ]
]

{ #category : #'as yet unclassified' }
JXReader >> processNumber: anInteger [ 
	^ anInteger 
]

{ #category : #'as yet unclassified' }
JXReader >> processObjectDefinition: aDictionary [
	| relatedObject |
	relatedObject := self
		object: (aDictionary at: '@id')
		ofClass: (aDictionary at: '@class').
	aDictionary associations
		reject: [ :a | self isMetaAssociation: a ]
		thenDo: [ :a | 
			(relatedObject isKindOf: JXArray)
				ifTrue: [ | value |
					(a value isArray not and: [ a value isDictionary not ])
						ifTrue: [ relatedObject addAssociation: a key -> (self process: a value) ]
						ifFalse: [ value := a value isDictionary
								ifTrue: [ {a value} ]
								ifFalse: [ a value ].
							value first isDictionary
								ifTrue: [ value
										do: [ :aDict | 
											(aDict includesKey: '@class')
												ifTrue: [  ]
												ifFalse: [ aDict at: '@class' put: a key ] ].
									relatedObject addAssociation: a key -> (self process: value) ]
								ifFalse: [ relatedObject
										addAll: (value collect: [ :each | self process: each ]) ] ] ]
				ifFalse: [ self
						propertyAt: a key
						put: (self process: a value)
						forObject: relatedObject ] ].
	^ relatedObject
]

{ #category : #'as yet unclassified' }
JXReader >> processReference: aYetToProcess [
	^ references
		at: aYetToProcess
		ifAbsentPut: [ JXReference on: aYetToProcess ]
]

{ #category : #'as yet unclassified' }
JXReader >> processString: aString [ 
	^ aString 
]

{ #category : #'as yet unclassified' }
JXReader >> propertyAt: aPropertyName put: aValue forObject: aTargetObject [
	(aTargetObject class slots
		anySatisfy: [ :s | s name = aPropertyName ])
		ifFalse: [ aTargetObject class addInstVarNamed: aPropertyName ].
	(aTargetObject class slotNamed: aPropertyName)
		write: aValue
		to: aTargetObject
]

{ #category : #'as yet unclassified' }
JXReader >> resolveWellKnownClass: aClassReference [
( aClassReference = 'linked-hash-map') ifTrue: [ ^ Dictionary ].
 ( aClassReference = 'array') ifTrue: [ ^ JXArray  ].
]

{ #category : #'as yet unclassified' }
JXReader >> targetPackage [
	^ 'VB6-ProleapMetaModel'
]
