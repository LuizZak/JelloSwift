//
//  Dict.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

internal final class Node<TValue>: Linked where TValue: AnyObject {
    var Key: TValue?
    weak var Prev: Node?
    var Next: Node?
    
    var _next: Node<TValue>! {
        return Next
    }
    
    init() {
        
    }
    
    init(Key: TValue) {
        self.Key = Key
    }
}

internal final class Dict<TValue> where TValue: AnyObject {
    typealias LessOrEqual = (_ lhs: TValue, _ rhs: TValue) -> Bool
    
    private var _leq: LessOrEqual
    var _head: Node<TValue>
    
    public init(leq: @escaping LessOrEqual) {
        _leq = leq
        
        _head = Node()
        _head.Prev = _head
        _head.Next = _head
    }
    
    deinit {
        // Dismount references to allow ARC to do its job
        _head.loop { node in
            node.Prev = nil
            node.Next = nil
        }
        _head = Node()
    }
    
    public func Insert(key: TValue) -> Node<TValue> {
        return InsertBefore(node: _head, key: key)
    }
    
    public func InsertBefore(node: Node<TValue>, key: TValue) -> Node<TValue> {
        var node = node
        
        repeat {
            node = node.Prev!
        } while (node.Key != nil && !_leq(node.Key!, key))
        
        let newNode = Node<TValue>(Key: key)
        newNode.Next = node.Next
        node.Next?.Prev = newNode
        newNode.Prev = node
        node.Next = newNode
        
        return newNode
    }
    
    public func Find(key: TValue) -> Node<TValue> {
        var node = _head
        repeat {
            node = node.Next!
        } while (node.Key != nil && !_leq(key, node.Key!))
        return node
    }
    
    public func Min() -> Node<TValue>? {
        return _head.Next
    }
    
    public func Remove(node: Node<TValue>) {
        node.Next?.Prev = node.Prev
        node.Prev?.Next = node.Next
        
        node.Next = nil
        node.Prev = nil
    }
}
