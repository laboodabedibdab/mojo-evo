
"""
Поле,Биты,Размер,Описание
PointerIndex,0-23,24 бита,Позиция на карте 4096×4096
Energy,24-33,10 бит,0–1023 (твой предел)
Genome PC,34-43,10 бит,Указатель на команду (до 1024 инструкций в геноме!)
Flags,44-75,32 бита,8 флагов по 4 бита (или 32 булевых флага)
Specs,76-125,50 бит,"5 параметров (сипа «сила», «защита» и т.д.) по 10 бит"
Type Tag,126-127,2 бита,"01 — живой агент, 10 — труп, 00/11 — пусто"


Короче флаги:
фотосинтез с>>6
атака с>>4
переработка органики(трупоедство) o*c >> 10
передача энергии o*c >> 8
деление o*c >> 11 и это же ребенку
"""


from std.memory import bitcast



def move(dr:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt128(energy>3)
    empty_space_flag=UInt128((sim[i*8+lookup[dr]]<<126>>126)==0)
    agent = (sim+i*8).load[width=8]()
    agent[0] &= ~(1023<<94)
    agent[0] |= (energy-3)<<94
    (sim+i*8).store(agent&(~((~valid_energy_flag)|empty_space_flag)))
    move_place = ((sim+i*8+lookup[dr]).load[width=8]()& ~empty_space_flag)|(agent&(valid_energy_flag&empty_space_flag))
    (sim+i*8+lookup[dr]).store(move_place)

def photosyntez(mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    agent = (sim+i*8).load[width=8]()
    agent[0] &= ~(1023<<94)
    agent[0] |= (energy+())<<94
    (sim+i*8).store(

def eat(dir:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en +en_org -2

def attack(dir:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en -(50-30*at_stat)

def divide(dir:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en half

def defend(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en -10

def rest(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en -1

def deep_sleep(sleep_ticks: Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en -5

def talk_to(dir:Int, message: UInt128, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en -2

def give_energy(dir:Int, amount: Int8, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass #en -am*alt_stat


def jmp(all_cond: UInt128, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]) -> Bool:
    pass

def stop(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass

def set_flag(flag_i: Int, value, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass

def get_flag(flag_i: Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]) -> UInt8:
    pass







def main():
    var wh = 4096
    var ww = wh
    var ag_size_specs = 1
    var ag_size_mind = 7
    var sim = alloc[UInt128](wh*ww*(ag_size_specs+ag_size_mind))
