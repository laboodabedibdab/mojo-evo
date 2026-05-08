"""
Поле,Биты,Размер,Описание
PointerIndex,0-23,24 бита,Позиция на карте 4096×4096
Energy,24-33,10 бит,0–1023 (твой предел)
Flags,44-75,32 бита,4 флага по 8 бит (или 32 булевых флага)
Genome PC,34-43,10 бит,Указатель на команду (до 1024 инструкций в геноме!)
Specs,76-125,50 бит,"5 параметров (сипа «сила», «защита» и т.д.) по 10 бит"
Type Tag,126-127,2 бита,"01 — живой агент, 10 — труп, 00/11 — пусто"


Короче флаги:
фотосинтез с>>6
атака 64 - с>>4
переработка органики(трупоедство) o*c >> 10
передача энергии o*c >> 8
деление o*c >> 11 и это же ребенку


move           0000
photosyntez    0001
eat            0010
attack         0011
divide         0100
rest           0101
deep_sleep     0110
talk_to        0111
give_energy    1000
jmp            1001
stop           1010
set_flag       1011
get_flag       1100
add            1101
sub            1110
mul            1111



jmp (comp var1 oper > < = != var2)(comp var1 oper > < = != var2)(comp var1 oper > < = != var2) jmp



параметры(25):
энергия
x
y
возраст
ltd
mtd
rtd
mld
mrd
lbd
mbd
rbd
4 флага
5 параметров

add photosyntez photosyntez photosyntez divide move
1101 0001 0001 0001 
.
"""


from std.memory import bitcast

def print_bin(val: UInt128):
    for i in range(128):
        print((val<<i)>>127, end="")
    print()

def print_agent(val: UInt128):
    if val<<126>>126:
        print("Agent index: "+String(val>>108))
        print("Energy: "+String(val<<24>>118))
        for flag in range(8):
            print((val<<(34+(flag*4)))>>124)
        print("Command index: "+String(val<<34>>118))
        print("photosyntez: "+String(val<<76>>118))
        print("attack: "+String(val<<86>>118))
        print("eat: "+String(val<<96>>118))
        print("altruism: "+String(val<<106>>118))
        print("divide: "+String(val<<116>>118))
    else:
        print("EMPTY SPACE")

def move(dr:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt(0)-UInt128(energy>3)
    empty_space_flag=UInt(0)-UInt128(Int((sim[i*8+lookup[dr]]<<126>>126)==0))
    agent = (sim+i*8).load[width=8]()
    agent[0] &= ~(1023<<94)
    agent[0] |= (energy-3)<<94
    (sim+i*8).store(agent&(~((~valid_energy_flag)|empty_space_flag)))
    move_place = ((sim+i*8+lookup[dr]).load[width=8]()& ~empty_space_flag)|(agent&(valid_energy_flag&empty_space_flag))
    (sim+i*8+lookup[dr]).store(move_place)

def photosyntez(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    agent = (sim+i*8).load[width=8]()
    energy = sim[i*8]<<24>>118
    agent[0] &= ~(1023<<94)
    ph_stat = agent[0]>>6
    agent[0] |= ((energy+ph_stat)&1023)<<94
    (sim+i*8).store(agent)

def eat(dir:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt(0)-UInt128(energy>3)
    organic_space_flag=UInt(0)-UInt128(Int((sim[(i*8+lookup[dr])&16777215]&3)==2))
    add_energy = ((sim[(i*8+lookup[dr])&16777215]<<24>>118)*(sim[i*8]<<96>>118))>>10
    add_energy&=organic_space_flag
    agent = (sim+i*8).load[width=8]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy+add_energy)&1023)<<94
    agent[0]&=valid_energy_flag
    (sim+i*8).store(agent)
    



def attack(dir:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    energy_loss=64-(sim[i*8]<<86>>118)
    valid_energy_flag=UInt(0)-UInt128(energy>energy_loss)
    enemy_space_flag=UInt(0)-UInt128(Int((sim[(i*8+lookup[dr])&16777215]&3)==1))
    
    agent = (sim+i*8).load[width=8]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy-energy_loss)&1023)<<94
    agent[0]&=valid_energy_flag

    


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
    return True

def stop(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass

def set_flag(flag_i: Int, value: UInt8, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass

def get_flag(flag_i: Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]) -> UInt8:
    return UInt8(0)







def main():
    var wh = 4096
    var ww = wh
    var ag_size_specs = 1
    var ag_size_mind = 7
    var sim = alloc[UInt128](wh*ww*(ag_size_specs+ag_size_mind))
    var Adam = SIMD[DType.uint128, 8](10141204801825835493723748958465,0,0,0,0,0,0,0)
    sim.store(Adam)
    print_agent(sim[0])
    print_bin(sim[0])
    photosyntez(0,sim)
    print_agent(sim[0])
    print_bin(sim[0])