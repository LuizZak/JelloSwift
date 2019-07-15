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
    
    func setData(_ data: [T], device: MTLDevice) {
        reserve(count: data.count, device: device)
        
        buffer.contents()
            .assumingMemoryBound(to: T.self)
            .assign(from: data, count: data.count)
    }
    
    func reserve(count: Int, device: MTLDevice) {
        if length > count {
            return
        }
        
        length = count
        let newSize = length * MemoryLayout<T>.stride
        guard let buffer = device.makeBuffer(length: newSize, options: .storageModeShared) else {
            fatalError("Could not allocate buffer with size \(newSize)")
        }
        
        self.buffer = buffer
    }
}
