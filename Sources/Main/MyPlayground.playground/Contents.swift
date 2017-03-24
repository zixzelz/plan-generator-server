//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

typealias Done = () -> Void
typealias Next = (_ done: @escaping Done) -> Void

class Make {

    private var block: Next?
    
    private var parent: Make?
    private var child: Make?

    init() {
        print("init \(self)")
    }

    init(block: @escaping Next, parent: Make) {
        print("init block \(self)")
        self.block = block
        self.parent = parent
    }

    func next(block: @escaping Next) -> Make {
        return Make(block: block, parent: self)
    }

    func start(done: Done?) {
        print("start: \(self)")

        if let parent = parent {
            print("has parent \(parent)")
            parent.start(done: { 
                
                self.block?({
                    done?()
                })
                
            })
        } else {
            print("has not got parent \(self)")
            done?()
        }
    }

    func step() {
        
    }
    
}

func a1(completion: @escaping () -> ()) {

//    DispatchQueue.main.asyncAfter(deadline: .now()) {
        print("work a1")
        completion()
//    }

}

func a2(completion: @escaping () -> ()) {

//    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        print("work a2")
        completion()
//    }

}

Make().next(block: { (done) in
    print("will a1")
    a1() {
        print("done a1")
        done()
    }

}).next(block: { (done) in
    print("will a2")
    a2() {
        print("done a2")
        done()
    }

}).start { (done) in
    print("start done")
}



