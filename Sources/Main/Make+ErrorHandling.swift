//
//  Make+ErrorHandling.swift
//  plan-generator-server
//
//  Created by Ruslan Maslouski on 3/31/17.
//
//

public protocol ResultType {

    associatedtype Value = Any
    associatedtype Err = Error

    var value: Value? { get }
    var error: Err? { get }

}

extension MakeOne where OutValue : ResultType {
    
    public func handleError (_ handler: @escaping (OutValue.Err) -> Void) -> MakeOne<OutValue, OutValue.Value> {
        let mainBlock: MakeVoidBlock<OutValue.Value> = { done in
            print("call mainBlock")
            
            self.main() { res in
                
                if let error = res.error {
                    handler(error)
                } else if let value = res.value {
                    done(value)
                }
            }
        }
        
        return MakeOne <OutValue, OutValue.Value> (main: mainBlock)
    }
}
