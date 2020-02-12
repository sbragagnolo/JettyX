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
	name := name copyReplaceAll: '$' with: 'GENERATED'.
	^ ('VB6' , name capitalized) asSymbol
]

{ #category : #'parsing-internal' }
JXStreamReader >> commonSuperClass [
	^ JXObject
]

{ #category : #'parsing-internal' }
JXStreamReader >> findClassByName: aClassName ifNone: aBlockClosure [
	^ (self isWellKnownClass: aClassName)
		ifTrue: [ self resolveWellKnownClass: aClassName ]
		ifFalse: [ classRegistry at: aClassName ifAbsentPut: [ aBlockClosure value ] ]
]

{ #category : #'parsing-internal' }
JXStreamReader >> initialize [
	super initialize.
	classRegistry := Dictionary new
]

{ #category : #'parsing-internal' }
JXStreamReader >> installClassNamed: aClassName [
	| symbolName |
	symbolName := self classSymbolNameFor: aClassName.
	(self class environment includesKey: symbolName)
		ifTrue: [ ^ self class environment at: symbolName ].
	^ self commonSuperClass
		subclass: symbolName
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
	('-' split: aName) size > 1
		ifTrue: [ ^ true ].
	^ {'string' . 'int'} includes: aName
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
	^ ('-' split: aName) size > 1 or: [ {'string' . 'int'} includes: aName ].
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseMap [
	| map |
	map := STON mapClass new.
	
	self parseMapDo: [ :k :v |
		| key value | 
		key := k. 
		value := v.	
		
		(self isReferenceString: key) ifTrue: [ 
			map := JXReference index: value 	.
		 ] ifFalse: [
			(self isClassName: key) ifTrue: [  
					| object |	
					
				value isReference ifTrue:[ object := value ] ifFalse: [
					(value isKindOf: Array ) ifTrue: [  
						object := OrderedCollection new.
						value do: [ : dic | 
							| oc |
							oc :=  self instantiate: key.	
							
						(dic isKindOf: Dictionary) ifTrue: [
							dic keysAndValuesDo: [ :nnnnn :vvvvv | self propertyAt: nnnnn put: vvvvv forObject: oc. ].
						] ifFalse:[
							oc setValue: dic.
						].	
						object add: oc. 
							
						]
						
						
					]ifFalse: [
						object := self instantiate: key.		
						(value isKindOf: Dictionary) ifTrue: [
							value keysAndValuesDo: [ :nnnnn :vvvvv | self propertyAt: nnnnn put: vvvvv forObject: object. ].
						] ifFalse:[
							object setValue: value.
						].
					]
				].
					
				self propertyAt: '__class' put: key forObject: object.
				key := 'mapping__',( UUID new asString copyReplaceAll: '-' with:'')  .
				value := object. 
			] ifFalse: [
				(self isClassReference: key) ifTrue: [  
					| object |	
					object := self instantiate: value. 
					map keysAndValuesDo: [ :nnnnn : vvvvv | self propertyAt: nnnnn put: vvvvv forObject: object. ].
					map := object. 
				]
			].
		
			self propertyAt: key put: value forObject: map.
		].

		
	].
	self storeReference: map.
	^ map
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseMap2 [
	| map association |
	map := STON mapClass new.
	association := nil. 
	self expectChar: ${.
	(self matchChar: $}) ifTrue: [ self storeReference: map. ^ map ].	"short cut for empty maps"
		
	[ readStream atEnd ] whileFalse: [ 
	
	| name value |
			name := self parseSimpleValue.
			self expectChar: $:.
			(self isClassName: name) ifTrue: [ 
					map := self parseObjectOfJavaClass: name.
					self storeReference: map.
					(association isNil and: [ self matchChar: $} ]) ifTrue: [ ^ map ]
						ifFalse: [
							 association ifNil: [ 
								self storeReference: association. 
									association := JXAssociation new. 
									association map: map type: name.
									map := nil 
								] ifNotNil: [ 
									association map: map type: name.
									map := nil. 
									^ association . 
								] 
						] 
			].
			(self isReferenceString: name) ifTrue: [ 
				self assert: map isEmpty.
					map := self parseXStreamReference: name.
					self storeReference: map.
					self assert: (self matchChar: $}).
					^ map 
				].
			association ifNil: [
				value := self parseValue.
				(self isIdReference: name) ifTrue: [ 
					name := 'id'.
					value := value asNumber 
				].
				(self isClassReference: name) ifTrue: [ 
					self assert: map isEmpty.
					self expectChar: $,.
					map := self parseObjectOfJavaClassInsideScope: value.
					self storeReference: map.
					^ map 
				].
			map at: name put: value.].
			"The above is a more efficient way to say 'self parseValue' and using the returned association"
			(self matchChar: $})
				ifTrue: [ self storeReference: map.
					^ map ].
			self expectChar: $, ].
	self error: 'end of map expected'.
	^ map
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseObjectOfJavaClass: aName [
	| value array |
	(self isWellKnownClass: aName)
		ifTrue: [ ^ self resolveValueForClass: aName  ].
	
	(self matchChar:$[) ifTrue:  [ 
			array := OrderedCollection new. 
			self storeReference: array. 
		[(self matchChar:$]) ] whileFalse:[
			array add: (self parseObjectOfJavaClass: aName).
		].
		^ array.
	].

	self matchChar: ${.
		value := self parseObjectOfJavaClassInsideScope: aName.
		(value isKindOf: JXReference ) ifFalse: [ 
		self expectChar: $}.
	].
	^ value
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseObjectOfJavaClassInsideScope: aName [
	| object |
	
	
	[ readStream atEnd ] whileFalse: [ | name value |
		name := self parseSimpleValue.
		self expectChar: $:.
			(self isReferenceString: name) ifTrue: [ 
				self assert: object isNil.
					object := self parseXStreamReference: name.
					self storeReference: object.
					self assert: (self matchChar: $}).
					^ object 
				].
		object ifNil:[  
			object := self instantiate: aName.
			self storeReference: object.
		].
		value := self parseValue.
		self propertyAt: name put: value forObject: object.
		"The above is a more efficient way to say 'self parseValue' and using the returned association"
		(self matchChar: $}) ifTrue: [ ^ object ].
		self expectChar: $, ].
	
	^ object
]

{ #category : #'parsing-internal' }
JXStreamReader >> parseXStreamReference: aReference [
	| value |
	value := self parseValue.
	^ JXReference index: value
]

{ #category : #'parsing-internal' }
JXStreamReader >> propertyAt: aPropertyName put: aValue forObject: aTargetObject [
	| prop val |
	prop := aPropertyName = '@id'
		ifTrue: [ '__id' ]
		ifFalse: [ aPropertyName ].
	prop := prop = '@serialization'
		ifTrue: [ '__serialization' ]
		ifFalse: [ prop ].
	prop := prop = '@class'
		ifTrue: [ '__class' ]
		ifFalse: [ prop ].
	
	val := (aValue isString and: [ aValue isAllDigits ])
		ifTrue: [ aValue asNumber ]
		ifFalse: [ aValue ].
	(aTargetObject isKindOf: Dictionary)
		ifTrue: [ aTargetObject at: prop put: val.
			^ self ].
	(aTargetObject class allSlots anySatisfy: [ :s | s name = prop ])
		ifFalse: [ aTargetObject class addInstVarNamed: prop ].
	(aTargetObject class slotNamed: prop) write: val to: aTargetObject
]

{ #category : #'as yet unclassified' }
JXStreamReader >> resolveValueForClass: aString [
	aString = 'string'
		ifTrue: [ ^ self parseValue ].
	aString = 'int'
		ifTrue: [ ^ self parseValue asNumber ].
	self error: ' trying to resolve invalide type' , aString
]

{ #category : #'parsing-internal' }
JXStreamReader >> resolveWellKnownClass: aClassReference [
	aClassReference = 'linked-hash-map'
		ifTrue: [ ^ JXDictionary ].
	aClassReference = 'array'
		ifTrue: [ ^ JXArray ].
	aClassReference = 'string'
		ifTrue: [ ^ JXString ].
	aClassReference = 'int'
		ifTrue: [ ^ JXInt ].
	self error: 'not known'
]

{ #category : #'parsing-internal' }
JXStreamReader >> storeReference: aMap [
	^ super storeReference: aMap
]

{ #category : #'parsing-internal' }
JXStreamReader >> targetPackage [
	^ 'VB6-ProleapMetaModel'
]
