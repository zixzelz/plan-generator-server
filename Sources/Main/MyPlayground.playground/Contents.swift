//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true
//enum Result<Value, Error: Swift.Error> {
//    case success(Value)
//    case error(Error)
//}

typealias MakeBlock <V, U> = (_ result: V, _ done: @escaping (_ result: U) -> Void) -> Void
typealias MakeVoidBlock <U> = (_ done: @escaping (_ result: U) -> Void) -> Void

struct Make {
    static func next <U> (block: @escaping MakeVoidBlock<U>) -> MakeOne<Void, U> {

        let mainBlock: MakeVoidBlock<U> = { done in
            block(done)
        }

        return MakeOne <Void, U> (main: mainBlock)
    }
}

struct MakeOne<InValue, OutValue> {

    typealias MainBlock = MakeVoidBlock<OutValue>

    private var main: MainBlock

    init(main: @escaping MainBlock) {
        self.main = main
        print("init block \(self)")
    }

    func next <U> (block: @escaping MakeBlock<OutValue, U>) -> MakeOne<OutValue, U> {

        let mainBlock: MakeVoidBlock<U> = { done in
            print("call mainBlock")

            self.main() { res in

                block(res, done)
            }
        }

        return MakeOne <OutValue, U> (main: mainBlock)
    }

    func completed(block: @escaping (_ result: OutValue) -> Void) {
        print("call completed")

        main(block)
    }

    func map <U> (_ transform: @escaping (OutValue) -> U) -> MakeOne<OutValue, U> {
        let mainBlock: MakeVoidBlock<U> = { done in
            print("call mainBlock")

            self.main() { res in
                done(transform(res))
            }
        }

        return MakeOne <OutValue, U> (main: mainBlock)
    }

}

func work1(p1: Int, completion: @escaping (_ result: Int) -> Void) {
    DispatchQueue.main.async {
        completion(p1 * 2)
    }
}

func work2(_ p1: String, completion: @escaping (_ result: String) -> Void) {
    DispatchQueue.main.async {
        completion(p1)
    }
}

func work3(el1: String, el2: String, completion: @escaping (_ result: [String]) -> Void) {
    DispatchQueue.main.async {
        completion([el1, el2])
    }
}

Make.next { (done: @escaping (Int) -> Void) in
    print("begin")
    work1(p1: 2) { res in
        done(res)
    }

}.map {"\($0)"}
.next { (res, done: @escaping (String) -> Void) in

    print("res of work 1: \(res)") // "4"
    let p1 = res + ".1"
    work2(p1) { res in
        done(res)
    }

}.next { (res, done: @escaping ([String]) -> Void) in

    print("res of work 2: \(res)")
    let salt = "salt"
    work3(el1: res, el2: salt) { res in
        done(res)
    }

}.completed { (res) in

    print("completed: \(res)") // ["4.1", "salt"]
}

print("Finish")


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


