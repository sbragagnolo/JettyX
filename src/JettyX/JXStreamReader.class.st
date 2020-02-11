Class {
	#name : #JXStreamReader,
	#superclass : #STONReader,
	#instVars : [
		'classRegistry'
	],
	#category : #JettyX
}

{ #category : #'parsing-internal' }
JXStreamReader >> classSymbolNameFor: aClassName [
	| name |
	name := ('.' split: aClassName) last copyReplaceAll: 'Impl' with: ''.
	^ 'VB6' , name capitalized
]

{ #category : #'parsing-internal' }
JXStreamReader >> commonSuperClass [
	^ Object
]

{ #category : #'parsing-internal' }
JXStreamReader >> findClassByName: aClassName ifNone: aBlockClosure [
	^ (self isWellKnownClass: aClassName)
		ifTrue: [ self resolveWellKnownClass: aClassName ]
		ifFalse: [ classRegistry at: aClassName ifAbsentPut: [ aBlockClosure value ] ]
]

{ #category : #'parsing-internal' }
JXStreamReader >> installClassNamed: aClassName [
	| symbolName |
	symbolName := self classSymbolNameFor: aClassName.
	(self class environment includesKey: symbolName)
		ifTrue: [ ^ self class environment at: symbolName ].
	^ self commonSuperClass
		subclass: (self classSymbolNameFor: aClassName)
		instanceVariableNames: ''
		classVariableNames: ''
		package: self targetPackage
]

{ #category : #'parsing-internal' }
JXStreamReader >> instantiate: aClassName [
	^ (self
		findClassByName: aClassName
		ifNone: [ self installClassNamed: aClassName ]) new
]

{ #category : #'parsing-internal' }
JXStreamReader >> isClassName: aName [
	('.' split: aName) size > 1
		ifTrue: [ ^ true ].
	^ ('-' split: aName) size > 1
]

{ #category : #'parsing-internal' }
JXStreamReader >> isClassReference: aName [
	^ aName = '@class'
]

{ #category : #'parsing-internal' }
JXStreamReader >> isIdReference: aName [
	^ aName = '@id'
]

{ #category : #'parsing-internal' }
JXStreamReader >> isReferenceString: aName [
	^ aName = '@reference'
]

{ #category : #'parsing-internal' }
JXStreamReader >> isWellKnownClass: aName [
	^ ('-' split: aName) size > 1 
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseMap [
	| map |
	map := STON mapClass new.
	
	
 	self expectChar: ${.
	(self matchChar: $}) ifTrue: [self storeReference: map. ^ map ]. "short cut for empty maps"
	[ readStream atEnd ] whileFalse: [ | name value |
		name := self parseSimpleValue.
		self expectChar: $:.
		
		(self isClassName: name ) ifTrue: [ 
			self assert: map isEmpty. 
			map := self parseObjectOfJavaClass: name. 
			self storeReference: map. 
			self assert: (self matchChar: $} ).
			^ map  
		].
		(self isReferenceString: name) ifTrue: [ 
			self assert: map isEmpty. 
			map := self parseXStreamReference: name. 
			self storeReference: map. 
			self assert: (self matchChar: $} ).
			^ map  
		].
		
		value := self parseValue.
		(self isIdReference: name) ifTrue: [ 
			self assert: objects size = value .
		].
		(self isClassReference: name) ifTrue: [ 
		
			self assert: map isEmpty. 
			map := self parseObjectOfJavaClassInsideScope: name. 
			self storeReference: map. 
			^ map  
		].
		
		map at: name put: value. 
		"The above is a more efficient way to say 'self parseValue' and using the returned association"
		(self matchChar: $}) ifTrue: [self storeReference: map. ^ map ].
		self expectChar: $, ].
	self error: 'end of map expected'.
	


	^ map
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseObjectOfJavaClass: aName [
	| value |
	self expectChar: ${.
	value := self parseObjectOfJavaClassInsideScope: aName.
	self expectChar: $}.
	^ value
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseObjectOfJavaClassInsideScope: aName [
	| object |
	object := self instantiate: aName.
	self storeReference: object.
	self
		parseMapDo:
			[ :key :value | self propertyAt: key put: value forObject: object ].
	^ object
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseString [ 
	| string | 
	string := super parseString. 
	(string beginsWith: '@' ) ifTrue: [ 
		^ self manageReference: string.	
	 ]
]

{ #category : #'parsing-internal' }
JXStreamReader >> resolveWellKnownClass: aClassReference [
	aClassReference = 'linked-hash-map'
		ifTrue: [ ^ Dictionary ].
	aClassReference = 'array'
		ifTrue: [ ^ JXArray ]
]

{ #category : #'parsing-internal' }
JXStreamReader >> targetPackage [
	^ 'VB6-ProleapMetaModel'
]
