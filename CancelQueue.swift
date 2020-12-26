//
//  CancelQueue.swift
//  AutoCompleteMe
//
//  Created by Seoksoon Jang on 2020/11/15.
//  Copyright © 2020 CurryingCat. All rights reserved.
//

import Foundation

/**
 *  CancelQueue
 */
struct CancelQueue {
    // FIXME: Code Duplication
    struct global {
        static func async(_ position: Position = .suffix(1),
                          sec:TimeInterval = 1,
                          immediateStartCapacity: Int = 0,
                          order: Sort = .desc, 
                          qos: DispatchQoS.QoSClass = .default,
                          isForceRefresh: Bool = false,
                          _ value: @escaping ()->Void) {
            if isForceRefresh {
                queue.clear()
                timer?.invalidate()
            }
            
            queue.enqueue(value)
            
            if queue.count() <= immediateStartCapacity {
                self.execute(position, order: order, block:.async)
            } else {
                timer?.invalidate()
                
                timer = Timer.scheduledTimer(withTimeInterval: sec, repeats: false) { timer in
                    self.execute(position, order: order, block:.async)
                    timer.invalidate()
                    
                    queue.clear()
                }
            }
        }
        
        static func sync(_ position: Position = .suffix(1),
                         sec:TimeInterval = 1,
                         immediateStartCapacity: Int = 0,
                          order: Sort = .desc,
                          qos: DispatchQoS.QoSClass = .default,
                          isForceRefresh: Bool = false, 
                          _ value: @escaping ()->Void) {
            if isForceRefresh {
                queue.clear()
                timer?.invalidate()
            }
            
            queue.enqueue(value)
            
            if queue.count() <= immediateStartCapacity {
                self.execute(position, order: order, block:.sync)
            } else {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: sec, repeats: false) { timer in
                    self.execute(position, order: order, block:.sync)
                    timer.invalidate()
                    
                    queue.clear()
                }
            }
        }
        
        static private var queue = Queue<()->Void>()
        static private var timer: Timer?
        static private let sec: TimeInterval = 1
        
        static private func execute(_ position: Position = .suffix(1),
                                    order:Sort = .desc,
                                    qos: DispatchQoS.QoSClass = .default,
                                    block: Block = .async) {
            var res = [()->Void]()
            if case .prefix(let count) = position {
                res = queue.prefix(count)
            }
            
            if case .suffix(let count) = position {
                res = queue.suffix(count)
            }
            
            res.sorted(by:{ _, _ in return order == .desc ? true : false })
               .forEach { task in
                if block == .async {
                    DispatchQueue.global(qos: qos).async {
                        task()
                    }
                } else {
                    DispatchQueue.global(qos: qos).sync {
                        task()
                    }
                }
            }
        }
    }
    
    // FIXME: Code Duplication
    struct main {
        static func async(_ position: Position = .suffix(1),
                          order: Sort = .desc,
                          _ value: @escaping ()->Void) {
            queue.enqueue(value)

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: sec, repeats: false) { timer in
                self.execute(position, order: order)
                timer.invalidate()
                
                queue.clear()
            }
        }
        
        static private var queue = Queue<()->Void>()
        static private var timer: Timer?
        static private let sec: TimeInterval = 1
        
        static private func execute(_ position: Position = .suffix(1), order:Sort = .desc) {
            var res = [()->Void]()
            if case .prefix(let count) = position {
                res = queue.prefix(count)
            }
            
            if case .suffix(let count) = position {
                res = queue.suffix(count)
            }
            
            res
            .sorted(by:{ _, _ in return order == .desc ? true : false })
            .forEach { task in
                DispatchQueue.main.async {
                    task()
                }
            }
        }
    }
    
    enum Sort {
        case desc
        case asc
    }
    
    enum Position {
        case suffix(Int)
        case prefix(Int)
    }
    
    enum Block {
        case async
        case sync
    }
    
    private struct Queue<T> {
        private var elements: [T] = []

        func count() -> Int {
            elements.count
        }
        
        func prefix(_ number: Int) -> [T] {
           Array(elements.prefix(number))
        }
        
        func suffix(_ number: Int) -> [T] {
           Array(elements.suffix(number))
        }
        
        func forEach(body: (T) throws -> Void) {
           try? elements.forEach(body)
        }
        
        mutating func clear() {
            elements = []
        }
        
        mutating func enqueue(_ value: T) {
            elements.append(value)
        }
        
        mutating func dequeue() -> T? {
            guard !elements.isEmpty else {
                return nil
            }
            return elements.removeFirst()
        }
        
        var head: T? {
            return elements.first
        }
        
        var tail: T? {
            return elements.last
        }
    }
}

// Given continuous async inputs, latest one is only executed, cancelling all other async calls.
//(0...1000).forEach { n in
//    CancelQueue.global.async {
//        print("=> \(n)")
//    }
//}

// => 10000


// style of how to execute async calls can be chosen for either prefix or suffix including order
// Leveraging DispatchQueue, you can choose block style either .sync or .async
//(0...1000).forEach { n in
//    CancelQueue.global.sync(.suffix(5), order:.desc) {
//        print("=> \(n)")
//    }
//}

//=> 1000
//=> 999
//=> 998
//=> 997
//=> 996


//(0...10).forEach { n in
//    CancelQueue.global.async(.prefix(5), order: .asc) {
//        print("*\(n)*")
//    }
//
//    CancelQueue.main.async(.suffix(6), order: .asc) {
//        print("@\(n)@")
//    }
//}

/*
 *0*
 *1*
 *2*
 *3*
 *4*
 @5@
 @6@
 @7@
 @8@
 @9@
 @10@
*/
