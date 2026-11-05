import Foundation

// Thread-safe state for a ring of GPU-owned vertex buffers.
// The render thread reserves only an idle, non-current buffer for CPU writes.
// Metal completion callbacks release per-frame references independently.
final class MorphBufferSlots {
    private let lock = NSLock()
    private var readers: [Int]
    private var reserved: Set<Int> = []
    private var current = 0

    init(count: Int = 3) {
        precondition(count >= 2)
        readers = Array(repeating: 0, count: count)
    }

    func reserveWrite() -> Int? {
        lock.lock(); defer { lock.unlock() }
        for i in readers.indices where i != current && readers[i] == 0 && !reserved.contains(i) {
            reserved.insert(i)
            return i
        }
        return nil
    }

    func publish(_ slot: Int) {
        lock.lock(); defer { lock.unlock() }
        precondition(reserved.remove(slot) != nil)
        precondition(readers[slot] == 0)
        current = slot
    }

    func cancelWrite(_ slot: Int) {
        lock.lock(); defer { lock.unlock() }
        precondition(reserved.remove(slot) != nil)
    }

    func retainCurrent() -> Int {
        lock.lock(); defer { lock.unlock() }
        precondition(!reserved.contains(current))
        readers[current] += 1
        return current
    }

    func release(_ slot: Int) {
        lock.lock(); defer { lock.unlock() }
        precondition(readers.indices.contains(slot) && readers[slot] > 0)
        readers[slot] -= 1
    }

    func snapshot() -> (current: Int, readers: [Int], reserved: Set<Int>) {
        lock.lock(); defer { lock.unlock() }
        return (current, readers, reserved)
    }
}
