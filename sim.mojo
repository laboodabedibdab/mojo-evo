
"""
Поле,Биты,Размер,Описание
PointerIndex,0-23,24 бита,Позиция на карте 4096×4096
Energy,24-33,10 бит,0–1023 (твой предел)
Genome PC,34-43,10 бит,Указатель на команду (до 1024 инструкций в геноме!)
Flags,44-75,32 бита,8 флагов по 4 бита (или 32 булевых флага)
Specs,76-125,50 бит,"5 параметров (сипа «сила», «защита» и т.д.) по 10 бит"
Type Tag,126-127,2 бита,"01 — живой агент, 10 — труп, 00/11 — пусто"
"""
from std.memory import bitcast



def move(dr:Int, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    valid_energy_flag=energy>3
    empty_space_flag=(sim[i*8+lookup[dr]]<<126>>126)==0
    agent = bitcast[DType.uint64, 16]((sim+i*8).load[width=8]())
    agent[0] &= ~(1023<<30)
    (sim+i*8).store(bitcast[DType.uint128, 8](agent)&(not ((not valid_energy_flag)|empty_space_flag)))
    (sim+i*8+lookup[dr]).store(bitcast[DType.uint128, 8](agent)&(valid_energy_flag&empty_space_flag))



    pass #en -1 -2

def photosyntez(mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en +4*ph_stat

def eat(dir:Int, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en +en_org -2

def attack(dir:Int, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en -(50-30*at_stat)

def divide(dir:Int, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en half

def defend(i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en -10

def rest(i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en -1

def deep_sleep(sleep_ticks: Int, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en -5

def talk_to(dir:Int, message: Float16, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en -2

def give_energy(dir:Int, amount: Int8, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass #en -am*alt_stat


def jmp(all_cond: UInt128, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]) -> Bool:
    pass

def stop(i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass

def set_flag(flag_i: Int, value, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]):
    pass

def get_flag(flag_i: Int, i: Int, mut sim: UnsafePointer[Float16, MutExternalOrigin]) -> UInt8:
    pass







def main():
    var wh = 4096
    var ww = wh
    var ag_size_specs = 1
    var ag_size_mind = 7
    var sim = alloc[UInt128](wh*ww*(ag_size_specs+ag_size_mind))
