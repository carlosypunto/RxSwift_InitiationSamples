/*: 

# initial concepts

*/




/*:

### map

*/



/*:

### filter

*/



/*:

### reduce

*/



/*

### function composition

Sometimes we need to pass the result of a function to another function

*/

func square(x: Double) -> Double {
    return x * x
}

func half(x: Double) -> Double {
    return x / 2
}

half(square(5))


//: To facilitate work, RxSwift provides us the `>-` operador, which is defined as follows:

infix operator >- { associativity left precedence 91 }
func >- <In, Out>(leftHandSide: In, rightHandSide: In -> Out) -> Out {
    return rightHandSide(leftHandSide)
}

//: with which we can write the above operation as follows

5 >- square >- half

//: so we get a much clearer syntax






/*:

### The Box Class

*/



