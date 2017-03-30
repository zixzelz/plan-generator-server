//
//  Result.swift
//  kitura-helloworld
//
//  Created by Ruslan Maslouski on 3/11/17.
//
//

import Foundation

enum MainResult<T , Err: Error> {
    case success(T)
    case failure(Err)
}

extension MainResult: ResultType {
    
    typealias Value = T

    public var error: Err? {
        return nil
    }
    
    public var value: Value? {
        guard case .success(let value) = self else { return nil }
        return value
    }
}
