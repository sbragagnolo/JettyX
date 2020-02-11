Extension { #name : #Dictionary }

{ #category : #'*JettyX' }
Dictionary >> beProcessedBy: aJXReader [
	^ aJXReader processDictionary: self
]
