import MetalKit

/// A wrapper over a growing Metal buffer
class MetalBuffer<T> {
    var buffer: MTLBuffer
    var length: Int
    
    convenience init?(device: MTLDevice, length: Int) {
        guard let buffer = device.makeBuffer(length: length * MemoryLayout<T>.stride, options: .storageModeShared) else {
            return nil
        }
        
        self.init(buffer: buffer, length: length)
    }
    
    init(buffer: MTLBuffer, length: Int) {
        self.buffer = buffer
        self.length = length
    }
    
    func setData(_ data: [T], device: MTLDevice) -> Bool {
        if !reserve(count: data.count, device: device) {
            return false
        }
        
        buffer.contents()
            .assumingMemoryBound(to: T.self)
            .assign(from: data, count: data.count)
        
        return true
    }
    
    func reserve(count: Int, device: MTLDevice) -> Bool {
        if length > count {
            return true
        }
        
        length = count
        let newSize = length * MemoryLayout<T>.stride
        guard let buffer = device.makeBuffer(length: newSize, options: .storageModeShared) else {
            return false
        }
        
        self.buffer = buffer
        return true
    }
}
