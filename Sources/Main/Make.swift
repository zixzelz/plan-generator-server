//
//  Make.swift
//  plan-generator-server
//
//  Created by Ruslan Maslouski on 3/26/17.
//
//

public typealias MakeBlock <V, U> = (_ result: V, _ done: @escaping (_ result: U) -> Void) -> Void
public typealias MakeVoidBlock <U> = (_ done: @escaping (_ result: U) -> Void) -> Void

public struct Make {
    public static func next <U> (block: @escaping MakeVoidBlock<U>) -> MakeOne<Void, U> {
        
        let mainBlock: MakeVoidBlock<U> = { done in
            block(done)
        }
        
        return MakeOne <Void, U> (main: mainBlock)
    }
}

public struct MakeOne<InValue, OutValue> {
    
    typealias MainBlock = MakeVoidBlock<OutValue>
    
    private var main: MainBlock
    
    fileprivate init(main: @escaping MainBlock) {
        self.main = main
        print("init block \(self)")
    }
    
    public func next <U> (block: @escaping MakeBlock<OutValue, U>) -> MakeOne<OutValue, U> {
        
        let mainBlock: MakeVoidBlock<U> = { done in
            print("call mainBlock")
            
            self.main() { res in
                
                block(res, done)
            }
        }
        
        return MakeOne <OutValue, U> (main: mainBlock)
    }
    
    public func completed(block: @escaping (_ result: OutValue) -> Void) {
        print("call completed")
        
        main(block)
    }
    
    public func map <U> (_ transform: @escaping (OutValue) -> U) -> MakeOne<OutValue, U> {
        let mainBlock: MakeVoidBlock<U> = { done in
            print("call mainBlock")
            
            self.main() { res in
                done(transform(res))
            }
        }
        
        return MakeOne <OutValue, U> (main: mainBlock)
    }
    
}
