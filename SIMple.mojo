from collections import List

struct Agent(Copyable):
    var index: UInt
    var energy: Int
    var genome: List[SIMD[DType.uint8, 6]]
    var command_pointer: Int
    var x: UInt16
    var y: UInt16
    var specs:SIMD[DType.uint8, 4]
    var vars:SIMD[DType.uint8, 4]
    
    def __init__(out self, index: UInt, energy: Int, x: UInt16, y: UInt16):
        self.index = index
        self.energy = energy
        self.x = x
        self.y = y
        self.genome = List[SIMD[DType.uint8, 6]]()
        self.specs = SIMD[DType.uint8, 4]()
        self.vars = SIMD[DType.uint8, 4]()
        #simd x*y
        #list(simd y)
        #list(list())
        self.command_pointer = 0

    def add_command(mut self, cmd: SIMD[DType.uint8, 6]):
        self.genome.append(cmd)

    def execute_current_command(mut self):
        if self.command_pointer >= len(self.genome):
            self.command_pointer = 0
        
        var cmd = self.genome[self.command_pointer]
        var commands = []
        # stop (1 ниббл)
        # move (2 ниббла)
        # photosyntez (1 ниббл)
        # eat (2 ниббла)
        # attack (2 ниббла)
        # divide (2 ниббла)
        # rest (1 ниббл)
        # deep_sleep (2 ниббла)
        # talk_to (4 ниббла)
        # give_energy (4 ниббла)
        # JMP (16 нибблов)
        # set_flag (4 ниббла)
        # get_flag (пока 4, хоть и удаляешь)
        # add (4 ниббла)
        # sub (4 ниббла)
        # резерев (1 ниббл)
    def stop(mut self, ):
        self.command_pointer = 0

    def move(mut self, args: SIMD[DType.uint8, 6]):
        if self.energy>=3 and :
            comptime dx = SIMD[DType.int8,8](-1,0,1,-1,1,-1,0,1)
            comptime dy = SIMD[DType.int8,8](1,1,1,0,0,-1,-1,-1)
            self.x = UInt16(Int8(self.x)+dx[Int(args[0])][0])
            self.y = UInt16(Int8(self.y)+dy[Int(args[0])][1])
        self.energy -=3

    def photosyntez(mut self):
        self.energy += 1
    
    def eat










   var org_ind: List[UInt]
    var free_org_ind
    var org_eng: List[UInt]



struct World:
    var agents: List[Agent]
    var xs: List[UInt16]
    var ys: List[UInt16]
    var energys: List[Int]
    var free_ind: List[UInt]
    var org: Dict[Tuple[UInt16, UInt16], UInt8]
    

    def __init__(out self):
        self.agents = List[Agent]()

    def add_agent(mut self,mut a: Agent):
        self.agents.append(a)

    def remove_agent(mut self, index: Int)

    def step(mut self):
        for i in range(len(self.agents)):
            self.agents[i].execute_current_command()

def main():
    var world = World()
    var adam = Agent(index=0, energy=100)
    
    # Добавляем команды "банально"
    adam.add_command(1) # move
    adam.add_command(2) # photo
    
    world.add_agent(adam)
    
    # Дебаг теперь элементарный
    print("Энергия агента:", world.agents[0].energy)
    world.step()
    print("Энергия после шага:", world.agents[0].energy)