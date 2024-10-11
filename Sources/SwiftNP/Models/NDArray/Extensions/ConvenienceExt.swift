//
//  File.swift
//  SwiftNP
//
//  Created by Arindam Karmakar on 11/10/24.
//

import Foundation

extension NDArray {
    
    /// Initializes an NDArray with a specified shape, data type, and default value.
    ///
    /// - Parameters:
    ///   - shape: An array of integers defining the shape of the NDArray.
    ///   - dtype: The data type of the elements in the NDArray (default is .float64).
    ///   - defaultValue: The value to fill the NDArray with.
    /// - Precondition: All dimensions in the shape must be non-negative.
    public convenience init(shape: [Int], dtype: DType = .float64, defaultValue: NSNumber) {
        // Ensure all dimensions in the shape are non-negative
        shape.forEach { precondition($0 >= 0, "Shape cannot be negative") }
        
        // Attempt to cast the default value to the specified data type
        guard let castedValue = dtype.cast(defaultValue) else {
            fatalError("Invalid default value")
        }
        
        var tmpArray: NDArray? = nil
        
        // Create a nested NDArray structure based on the specified shape
        for dim in shape.reversed() {
            if tmpArray != nil {
                tmpArray = NDArray(repeating: tmpArray!, count: dim, dtype: dtype)
            } else {
                tmpArray = NDArray(repeating: castedValue, count: dim)
            }
        }
        
        // Ensure the temporary array was created successfully
        guard let array = tmpArray else { fatalError("Unable to create array") }
        
        // Initialize the NDArray with the shape and data from the temporary array
        self.init(shape: array.shape, dtype: array.dtype, data: array.data)
    }
    
    /// Initializes an NDArray from a Swift array of any type.
    ///
    /// - Parameter array: An array containing elements of any type.
    /// - Precondition: The shape inferred from the array must match the number of elements.
    /// - Fatal error: Will occur if the array is empty or if dtype cannot be determined.
    public convenience init(array: [Any]) {
        let inferredShape = Utils.inferShape(from: array) // Infer shape from the array
        let flattenedArray = Utils.flatten(array) // Flatten the array
        
        // Check if the inferred shape matches the number of elements
        let totalSize = inferredShape.reduce(1, *)
        guard flattenedArray.count == totalSize else {
            fatalError("Shape \(inferredShape) does not match the total number of elements in the array: \(flattenedArray.count)")
        }
        
        // Automatically detect dtype based on the first element (assuming homogeneous array)
        guard let firstElement = flattenedArray.first as? any Numeric else {
            fatalError("Array is empty. Cannot determine dtype.")
        }
        guard let dtype = DType.typeOf(firstElement) else {
            fatalError("Could not determine dtype from array elements.")
        }
        
        // Initialize the NDArray with the inferred shape and dtype
        self.init(shape: inferredShape, dtype: dtype, data: array)
    }
    
    /// Initializes an NDArray by repeating a value a specified number of times.
    ///
    /// - Parameters:
    ///   - repeating: The value to be repeated (can be any type or NDArray).
    ///   - count: The number of times to repeat the value.
    ///   - dtype: The data type of the elements in the NDArray.
    internal convenience init(repeating: Any, count: Int, dtype: DType) {
        var shape = [count]
        
        // Determine the shape based on the type of the repeating value
        if let repeatingItem = repeating as? NDArray {
            shape.append(contentsOf: repeatingItem.shape)
        } else if let repeatingArray = repeating as? [NDArray] {
            shape.append(contentsOf: repeatingArray.first!.shape)
        }
        
        // Create an array of repeated values
        let data = Array(repeating: repeating, count: count)
        
        // Initialize the NDArray with the computed shape and data
        self.init(shape: shape, dtype: dtype, data: data)
    }
    
    /// Initializes an NDArray by repeating a numeric value a specified number of times.
    ///
    /// - Parameters:
    ///   - repeating: The numeric value to be repeated.
    ///   - count: The number of times to repeat the value.
    /// - Fatal error: Will occur if dtype cannot be determined from the repeating value.
    private convenience init(repeating: any Numeric, count: Int) {
        // Determine the data type of the repeating value
        guard let dtype = DType.typeOf(repeating) else { fatalError("Invalid input value") }
        
        // Create an array of repeated numeric values
        let data = Array(repeating: repeating, count: count)
        
        // Initialize the NDArray with the shape and data
        self.init(shape: [count], dtype: dtype, data: data)
    }
}
