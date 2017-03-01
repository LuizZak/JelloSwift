//
//  PriorityQueue.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 27/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

fileprivate class StackItem {
    var p = 0
    var r = 0
    
    init() {
        
    }
    
    init(p: Int, r: Int) {
        self.p = p
        self.r = r
    }
}

internal class PriorityQueue<TValue> where TValue: AnyObject {
    private var _leq: PriorityHeap<TValue>.LessOrEqual
    private var _heap: PriorityHeap<TValue>
    private var _keys: ContiguousArray<TValue?>
    private var _order: [Int] = []
    
    private var _size = 0, _max = 0
    private var _initialized = false
    
    public var Empty: Bool {
        return _size == 0 && _heap.Empty
    }
    
    public init(_ initialSize: Int, _ leq: @escaping PriorityHeap<TValue>.LessOrEqual) {
        _leq = leq
        _heap = PriorityHeap<TValue>(initialSize, leq)
        
        _keys = ContiguousArray<TValue?>(repeating: nil, count: initialSize)
        
        _size = 0
        _max = initialSize
        _initialized = false
    }
    
    deinit {
        
    }
    
    public func Init() {
        
        var stack = [StackItem]()
        var i: Int = 0, j: Int, piv: Int = 0
        var seed: UInt32 = 2016473283
        
        var p = 0
        var r = _size - 1
        
        _order = Array(repeating: 0, count: _size + 1)
        
        while i <= r {
            _order[i] = piv
            
            piv += 1
            i += 1
        }
        
        stack.append(StackItem(p: p, r: r))
        while (stack.count > 0) {
            let top = stack.removeLast()
            p = top.p
            r = top.r
            
            while (r > p + 10) {
                seed = seed &* 1539415821 &+ 1
                i = p + Int(seed % UInt32(r - p + 1))
                piv = _order[i]
                
                if(p != i) {
                    swap(&_order[i], &_order[p])
                }
                
                i = p - 1
                j = r + 1
                repeat {
                    repeat {
                        i += 1
                    } while (!_leq(keyForOrderAt(index: i), keyAt(index: piv)))
                    repeat {
                        j -= 1
                    } while (!_leq(keyAt(index: piv), keyForOrderAt(index: j)))
                    
                    if(i != j) {
                        swap(&_order[i], &_order[j])
                    }
                } while (i < j)
                
                if(i != j) {
                    swap(&_order[i], &_order[j])
                }
                
                if (i - p < r - j) {
                    stack.append(StackItem(p: j + 1, r: r))
                    r = i - 1
                } else {
                    stack.append(StackItem(p: p, r: i - 1))
                    p = j + 1
                }
            }
            
            i = p + 1
            while(i <= r) {
                piv = _order[i]
                
                j = i
                
                while j > p && !_leq(keyAt(index: piv), keyForOrderAt(index: j - 1)) {
                    _order[j] = _order[j - 1]
                    j -= 1
                }
                _order[j] = piv
                
                i += 1
            }
        }

#if DEBUG
        p = 0
        r = _size - 1
        i = p
        
        while i < r {
            assert(_leq(_keys[_order[i + 1]], _keys[_order[i]]), "Wrong sort")
            i += 1
        }
#endif

        _max = _size
        _initialized = true
        _heap.Init()
    }
    
    public func Insert(_ value: TValue) -> PQHandle {
        if (_initialized) {
            return _heap.Insert(value)
        }

        let curr = _size
        _size += 1
        if (_size >= _max) {
            _max <<= 1
            
            let diffK = _keys.count - _max + 1
            let subK = ContiguousArray<TValue?>(repeating: nil, count: diffK)
            
            _keys.append(contentsOf: subK)
        }

        _keys[curr] = value
        return PQHandle(handle: -(curr + 1))
    }

    public func ExtractMin() -> TValue? {
        assert(_initialized)
        if (_size == 0) {
            return _heap.ExtractMin()
        }
        
        let sortMin = lastKey()
        if (!_heap.Empty) {
            let heapMin = _heap.Minimum()
            if (_leq(heapMin, sortMin)) {
                return _heap.ExtractMin()
            }
        }
        
        repeat {
            _size -= 1
        } while (_size > 0 && lastKey() == nil)
        
        return sortMin
    }

    public func Minimum() -> TValue? {
        assert(_initialized)
        
        if (_size == 0) {
            return _heap.Minimum()
        }
        
        let sortMin = lastKey()
        
        if (!_heap.Empty) {
            let heapMin = _heap.Minimum()
            if (_leq(heapMin, sortMin)) {
                return heapMin
            }
        }
        
        return sortMin
    }

    public func Remove(_ handle: PQHandle) {
        assert(_initialized)
        
        var curr = handle._handle
        if (curr >= 0) {
            _heap.Remove(handle)
            return
        }
        
        curr = -(curr + 1)
        assert(curr < _max && keyAt(index: curr) != nil)
        
        _keys[curr] = nil
        while (_size > 0 && lastKey() == nil) {
            _size -= 1
        }
    }
    
    private func keyAt(index: Int) -> TValue? {
        return _keys[index]
    }
    
    private func keyForOrderAt(index: Int) -> TValue? {
        return keyAt(index: _order[index])
    }
    
    private func lastKey() -> TValue? {
        return keyForOrderAt(index: _size - 1)
    }
}
