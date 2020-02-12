Extension { #name : #Dictionary }

{ #category : #'*JettyX' }
Dictionary >> beProcessedBy: aJXReader [
	^ aJXReader processDictionary: self
]

{ #category : #'*JettyX' }
Dictionary >> storeAt: aPropertyName put: aValue [ 
	^ self at: aPropertyName put: aValue 
]
