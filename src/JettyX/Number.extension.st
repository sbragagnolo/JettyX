Extension { #name : #Number }

{ #category : #'*JettyX' }
Number >> beProcessedBy: aJXReader [ 
	^ aJXReader processNumber: self 
]
