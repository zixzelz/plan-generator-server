//: Playground - noun: a place where people can play

import UIKit

//enum Result<Value, Error: Swift.Error> {
//    case success(Value)
//    case error(Error)
//}

typealias MakeBlock <V, U> = (_ result: V, _ done: @escaping (_ result: U) -> Void) -> Void
typealias MakeVoidBlock <U> = (_ done: @escaping (_ result: U) -> Void) -> Void

class Makes {
    static func next <U> (block: @escaping MakeVoidBlock<U>) -> Make<Void, U> {
        let next: MakeBlock<Void, U> = { res, done in
            block(done)
        }
        return Make <Void, U> (block: next, main: nil)
    }
}

class Make<InValue, OutValue> {

    typealias Block = MakeBlock<InValue, OutValue>
    typealias MainBlock = () -> Void

    private var block: Block?
    private var main: MainBlock?

    init(block: Block?, main: MainBlock?) {
        print("init block \(self)")
        self.block = block
        self.main = main
    }
    
    func next <U> (block: @escaping MakeBlock<OutValue, U>) -> Make<OutValue, U> {
        
        let mainBlock: MainBlock = { [unowned self] _ in
            
            if let main = self.main {
                main()
            } else {
                block()
            }
            
        }
        
        return Make <OutValue, U> (block: block, main: mainBlock)
    }

    func completed(block: (_ result: OutValue) -> Void) {
        
        if let main = main {
            main()
        } else {
            self.block
        }
    }

//    func start(done: @escaping (_ result: InValue) -> Void) {
//        print("start: \(self)")
//
//        if let parent = parent {
//            print("has parent \(parent)")
//            parent.start(done: { result in
//
//                guard let block = self.block else {
//                    done(result)
//                    return
//                }
//                block(result, done)
//            })
//        } else {
//            print("has not got parent \(self)")
//            self.block?(self.initValue!, done)
//        }
//    }
//
//    func start(next: @escaping (_ result: InValue) -> Void) {
//
//        print("start next")
//        start(done: { result in
//            next(result)
//        })
//    }

}

Makes.next { (done: (Int) -> Void) in
    print("begin")
    done(5)
}.next { (res, done: (String) -> Void) in

    print("res: \(res)")
    let vc = "\(res * 2)"
    done(vc)
    
}.next { (res, done: ([String]) -> Void) in

    print("res: \(res)")
    let v = res + "00"
    done([res, v])
    
}.completed { (res) in
    print("res: \(res)")
}

//
//typealias a1Completion = Result<String, NSError>
//func a1(completion: @escaping (_ result: a1Completion) -> Void) {
//
//    //    DispatchQueue.main.asyncAfter(deadline: .now()) {
//    print("work a1")
//    completion(.success("a1"))
//    //    }
//
//}
//
//typealias a2Completion = Result<String, NSError>
//func a2(completion: @escaping (_ result: a2Completion) -> Void) {
//
//    //    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//    print("work a2")
//    completion(.success("a2"))
//    //    }
//
//}

//Make<Void, Void>().next { (result, done) in
//    done("")
//}


//Make().next(block: { (done) in
//    print("will a1")
//    a1() { result in
//        print("done a1")
//        done("")
//    }
//
//}).next(block: { (done) in
//    print("will a2")
//    a2() { result in
//        print("done a2")
//        done("")
//    }
//
//}).start(next: { result in
////    print("start done")
//})
//


