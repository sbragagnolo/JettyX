Extension { #name : #Array }

{ #category : #'*JettyX' }
Array >> beProcessedBy: aJXReader [
	^ aJXReader processArray: self
]
