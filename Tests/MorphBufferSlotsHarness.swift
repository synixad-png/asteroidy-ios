import Foundation

@main
struct Harness {
    static func main() {
        let r = MorphBufferSlots()
        let a = r.retainCurrent()
        precondition(a == 0)
        let next = r.reserveWrite()!
        precondition(next != a)
        precondition(r.reserveWrite() == 2)
        r.cancelWrite(2)
        r.publish(next)
        let b = r.retainCurrent()
        precondition(b == next)
        let third = r.reserveWrite()!
        precondition(third == 2) // buffer 0 still used by earlier GPU work
        r.publish(third)
        precondition(r.reserveWrite() == nil) // both other buffers still in flight
        r.release(a)
        let spare = r.reserveWrite()!
        precondition(spare == 0)
        r.cancelWrite(spare)
        r.release(b)
        let c = r.retainCurrent()
        r.release(c)
        precondition(r.snapshot().readers == [0,0,0])
        print("PASS: ring ownership, in-flight protection, backpressure, cancellation")
    }
}
