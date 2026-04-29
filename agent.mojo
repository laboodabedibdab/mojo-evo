from mind import Model
from std.sys.intrinsics import gather

struct Agent:
    var brain: Model
    # Статы: 0:Хищник, 1:Фотосинтез, 2:Сапротроф, 3:Альтруизм (эфф. передачи)
    var stats: SIMD[DType.float16, 4] 
    var energy: Int8
    var x: Int32
    var y: Int32
    var talk: Float16
    var inputs: SIMD[DType.float16, 16]

    def __init__(out self):
        self.brain = Model()
        self.stats = SIMD[DType.float16, 4](0.25, 0.25, 0.25, 0.25)
        self.inputs = SIMD[DType.float16, 16]()
        self.energy = 128
        self.x = 0
        self.y = 0
        self.talk = 0

    def get_data(read self) -> SIMD[DType.float16, 16]:
        return SIMD[DType.float16, 16](0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)


    def tick(mut self, world: UnsafePointer[Int8, MutExternalOrigin]):
        comptime dx = SIMD[DType.int64, 8](-1,  0,  1, -1, 1, -1, 0, 1)
        comptime dy = SIMD[DType.int64, 8](-1, -1, -1,  0, 0,  1, 1, 1)
        
        var nx = (self.x.cast[DType.int64]() + dx + 1024) & 1023
        var ny = (self.y.cast[DType.int64]() + dy + 1024) & 1023
        
        var offsets = (ny << 10) | nx
        var vision = world.gather[width=8](offsets.cast[DType.int32]())

        #8/16
        
        var state = SIMD[DType.float16, 4](0) 
        
        state[0] = Float16(self.x) / 1023
        state[1] = Float16(self.y) / 1023
        state[2] = Float16(self.energy) / 255
        state[3] = self.talk
        
        var internal = self.stats.join(state)
        
        # 3. Финальный аккорд: Зрение (8) + Внутрянка (8) -> 16
        self.inputs = vision.cast[DType.float16]().join(internal)

        self.brain.forward(self.inputs)
        
        #16/16
def main():
    var wrld = alloc[Int8](1024*1024)
    a = Agent()
    a.tick(wrld)