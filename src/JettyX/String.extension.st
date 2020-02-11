Extension { #name : #String }

{ #category : #'*JettyX' }
String >> beProcessedBy: aJXReader [ 
	^ aJXReader processString: self. 
]
