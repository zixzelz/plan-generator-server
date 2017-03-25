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

        let mainBlock: MakeVoidBlock<U> = { done in
            block(done)
        }

        return Make <Void, U> (main: mainBlock)
    }
}

class Make<InValue, OutValue> {

    typealias MainBlock = MakeVoidBlock<OutValue>

    private var main: MainBlock

    init(main: @escaping MainBlock) {
        self.main = main
        print("init block \(self)")
    }

    deinit {
        print("deinit block \(self)")
    }
    
    func next <U> (block: @escaping MakeBlock<OutValue, U>) -> Make<OutValue, U> {

        let mainBlock: MakeVoidBlock<U> = { done in
            print("call mainBlock")

            self.main() { res in
                
                block(res, done)
            }
        }

        return Make <OutValue, U> (main: mainBlock)
    }

    func completed(block: @escaping (_ result: OutValue) -> Void) {
        print("call completed")
        
        main(block)
    }

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

print("Finish")

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


