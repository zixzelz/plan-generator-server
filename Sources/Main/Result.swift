//
//  Result.swift
//  kitura-helloworld
//
//  Created by Ruslan Maslouski on 3/11/17.
//
//

import Foundation

enum MainResult<T ,Err: Error> {
    
    case success(T)
    case failure(Err)
}
