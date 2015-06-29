//
//  Q.swift
//  Q
//
//  Created by Damien on 29/06/2015.
//  Copyright (c) 2015 Damien. All rights reserved.
//

import Dispatch

public extension Double {
    public var second:  Double { return self }
    public var seconds: Double { return self }
    public var minute:  Double { return self * 60 }
    public var minutes: Double { return self * 60 }
    public var hour:    Double { return self * 3600 }
    public var hours:   Double { return self * 3600 }
    
    public var inNanoSeconds: Int64 { return Int64(self * Double(NSEC_PER_SEC)) }
}

private enum QueueType {
    case Main, Background, UserInteractive, UserInitiated, Utility, Custom(dispatch_queue_t)
    
    var queue: dispatch_queue_t {
        switch self {
        case .Main:
            return dispatch_get_main_queue()
        case .Background, .UserInteractive, .UserInitiated, .Utility:
            return dispatch_get_global_queue(self.qosClass, 0)
        case let .Custom(queue):
            return queue
        }
    }
    
    var qosClass: qos_class_t {
        switch self {
        case .Main: return qos_class_main()
        case .Background: return QOS_CLASS_BACKGROUND
        case .UserInteractive: return QOS_CLASS_USER_INTERACTIVE
        case .UserInitiated: return QOS_CLASS_USER_INITIATED
        case .Utility: return QOS_CLASS_UTILITY
        default: return QOS_CLASS_UNSPECIFIED
        }
    }
}

public struct Dispatcher {
    public typealias Block = dispatch_block_t
    
    private let block: Block
    
    private init(_ block: Block) {
        self.block = block
    }
}

extension Dispatcher {
    public static func main(block: Block) -> Dispatcher {
        return dispatch(.Main, block: block)
    }
    
    public static func background(block: Block) -> Dispatcher {
        return dispatch(.Background, block: block)
    }
    
    public static func userInteractive(block: Block) -> Dispatcher {
        return dispatch(.UserInteractive, block: block)
    }
    
    public static func userInitiated(block: Block) -> Dispatcher {
        return dispatch(.UserInitiated, block: block)
    }
    
    public static func utility(block: Block) -> Dispatcher {
        return dispatch(.Utility, block: block)
    }
    
    public static func custom(queue: dispatch_queue_t, block: Block) -> Dispatcher {
        return dispatch(.Custom(queue), block: block)
    }
    
    private static func dispatch(queueType: QueueType, block: Block) -> Dispatcher {
        let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
        dispatch_async(queueType.queue, block)
        return Dispatcher(block)
    }
}

extension Dispatcher {
    public static func main(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Main, block: block)
    }
    
    public static func background(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Background, block: block)
    }
    
    public static func userInteractive(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .UserInteractive, block: block)
    }
    
    public static func userInitiated(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .UserInitiated, block: block)
    }
    
    public static func utility(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Utility, block: block)
    }
    
    public static func custom(queue: dispatch_queue_t, after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Custom(queue), block: block)
    }
    
    private static func after(seconds: Double, queueType: QueueType, block: Block) -> Dispatcher {
        let time = dispatch_time(DISPATCH_TIME_NOW, seconds.inNanoSeconds)
        let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
        dispatch_after(time, queueType.queue, block)
        
        return Dispatcher(block)
    }
}

extension Dispatcher {
    public func main(block: Block) -> Dispatcher {
        return dispatch(.Main, block: block)
    }
    
    public func background(block: Block) -> Dispatcher {
        return dispatch(.Background, block: block)
    }
    
    public func userInteractive(block: Block) -> Dispatcher {
        return dispatch(.UserInteractive, block: block)
    }
    
    public func userInitiated(block: Block) -> Dispatcher {
        return dispatch(.UserInitiated, block: block)
    }
    
    public func utility(block: Block) -> Dispatcher {
        return dispatch(.Utility, block: block)
    }
    
    public func custom(queue: dispatch_queue_t, block: Block) -> Dispatcher {
        return dispatch(.Custom(queue), block: block)
    }
    
    private func dispatch(queueType: QueueType, block: Block) -> Dispatcher {
        let nextBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
        dispatch_block_notify(self.block, queueType.queue, nextBlock)
        
        return Dispatcher(nextBlock)
    }
}

extension Dispatcher {
    public func main(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Main, block: block)
    }
    
    public func background(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Background, block: block)
    }
    
    public func userInteractive(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .UserInteractive, block: block)
    }
    
    public func userInitiated(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .UserInitiated, block: block)
    }
    
    public func utility(after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Utility, block: block)
    }
    
    public func custom(queue: dispatch_queue_t, after seconds: Double, block: Block) -> Dispatcher {
        return after(seconds, queueType: .Custom(queue), block: block)
    }
    
    private func after(seconds: Double, queueType: QueueType, block: Block) -> Dispatcher {
        let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
        
        let nextBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
            let time = dispatch_time(DISPATCH_TIME_NOW, seconds.inNanoSeconds)
            dispatch_after(time, queueType.queue, block)
        }
        dispatch_block_notify(self.block, queueType.queue, nextBlock)
        
        return Dispatcher(nextBlock)
    }
}

extension Dispatcher {
    public func cancel() {
        dispatch_block_cancel(block)
    }
    
    public func wait(seconds: Double = 0) {
        if seconds > 0 {
            let time = dispatch_time(DISPATCH_TIME_NOW, seconds.inNanoSeconds)
            dispatch_block_wait(block, time)
        } else {
            dispatch_block_wait(block, DISPATCH_TIME_FOREVER)
        }
    }
}

public typealias Q = Dispatcher