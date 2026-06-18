from std.memory import bitcast

@always_inline
def get_index(header: UInt128) -> UInt128:
    return header >> 104

@always_inline
def get_energy(header: UInt128) -> UInt128:
    return (header << 24) >> 120

@always_inline
def get_innervar(header: UInt128, var_i: UInt128) -> UInt128:
    return (header << (32+(var_i*8))) >> 120

@always_inline
def get_nibble(header: UInt128) -> UInt128:
    return (header << 64) >> 120
    
@always_inline
def get_coef(header: UInt128, coef_i: UInt128) -> UInt128:
    return (header << (72+(coef_i*8))) >> 120
    
@always_inline
def get_age(header: UInt128) -> UInt128:
    return (header << 104) >> 106

@always_inline
def get_flag(header: UInt128) -> UInt128:
    return header & 3

@always_inline
def is_empty(header: UInt128) -> UInt128:
    return UInt128(0)-UInt128(Int((get_flag(header))==0))

@always_inline
def is_agent(header: UInt128) -> UInt128:
    return UInt128(0)-UInt128(Int((get_flag(header))==1))

@always_inline
def is_organic(header: UInt128) -> UInt128:
    return UInt128(0)-UInt128(Int((get_flag(header))==2))

@always_inline
def is_protected(header: UInt128) -> UInt128:
    return UInt128(0)-UInt128(Int((get_flag(header))==3))

@always_inline
def valid_energy(header: UInt128, tld: UInt128) -> UInt128:
    return UInt128(0)-UInt128(get_energy(header)>tld)


def print_bin(val: UInt128):
    for i in range(128):
        print((val<<UInt128(i))>>127, end="")
    print()

def print_agent(val: UInt128):
    if val<<126>>126:
        print("Agent index: "+String(val>>108))
        print("Energy: "+String(val<<24>>118))
        for flag in range(8):
            print((val<<UInt128(34+(flag*4)))>>124)
        print("Command index: "+String(val<<34>>118))
        print("photosyntez: "+String(val<<76>>118))
        print("attack: "+String(val<<86>>118))
        print("eat: "+String(val<<96>>118))
        print("altruism: "+String(val<<106>>118))
        print("divide: "+String(val<<116>>118))
    else:
        print("EMPTY SPACE")

def move(dr:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    place_header = sim[(i*8+Int(lookup[dr]))&16777215]
    agent_header = sim[(i*8)&16777215]
    energy = get_energy(agent_header)
    valid_energy_flag=valid_energy(place_header, 3)
    empty_space_flag=is_empty(place_header)
    agent = (sim+i*8).load[width=8]()
    agent[0] &= ~(1023<<94)
    agent[0] |= (energy-3)<<94
    (sim+i*8).store(agent&(~((~valid_energy_flag)|empty_space_flag)))
    move_place = ((sim+i*8+lookup[dr]).load[width=8]()& ~empty_space_flag)|(agent&(valid_energy_flag&empty_space_flag))
    (sim+i*8+lookup[dr]).store(move_place)
    agent_amount-=UInt32(Bool(not valid_energy_flag))

def photosyntez(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    agent = (sim+i*8).load[width=1]()
    energy = sim[i*8]<<24>>118
    agent[0] &= ~(1023<<94)
    ph_stat = agent[0]>>6
    agent[0] |= ((energy+ph_stat)&1023)<<94
    (sim+i*8).store(agent)

def eat(dr:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt128(0)-UInt128(energy>3)
    organic_space_flag=UInt128(0)-UInt128(Int((sim[(i*8+Int(lookup[dr]))&16777215]&3)==2))
    add_energy = ((sim[(i*8+Int(lookup[dr]))&16777215]<<24>>118)*(sim[i*8]<<96>>118))>>10
    add_energy&=organic_space_flag
    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy+add_energy)&1023)<<94
    agent[0]&=valid_energy_flag
    (sim+i*8).store(agent)
    agent_amount-=UInt32(Bool(not valid_energy_flag))
    



def attack(dr:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    energy_loss=64-(sim[i*8]<<86>>118)
    valid_energy_flag=UInt128(0)-UInt128(energy>energy_loss)
    
    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy-energy_loss)&1023)<<94
    agent[0]&=valid_energy_flag
    (sim+i*8).store(agent)

    who = sim[i*8+Int(lookup[dr])]&3
    a = who >> 1 # Старший бит
    b = who & 1        # Младший бит
    out_1 = a ^ b
    out_0 = a & b
    who = (out_1 << 1) | out_0
    sim[i*8+Int(lookup[dr])&16777215]&=(UInt128(-4)|~valid_energy_flag)
    sim[i*8+Int(lookup[dr])&16777215]|=(who&valid_energy_flag)
    agent_amount-=UInt32(Bool(not valid_energy_flag))
    


def divide(dr:Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    energy = sim[i*8]<<24>>118
    res_energy = (energy*((sim[i*8]<<116>>119)+512))>>11
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    #valid_energy_flag=UInt128(0)-UInt128(energy>3)
    empty_space_flag=UInt128(0)-UInt128(Int((sim[(i*8+Int(lookup[dr]))&16777215]<<126>>126)==0))
    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= (res_energy)<<94
    (sim+i*8).store(agent)
    clone = ((sim+((Int16(i*8)+lookup[dr])&16777215)).load[width=8]()& ~empty_space_flag)|(agent&empty_space_flag)
    (sim+i*8+lookup[dr]).store(clone)
    agent_amount+=UInt32(Bool(empty_space_flag))   

def defend(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt128(0)-UInt128(energy>15)
    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy-15)&1023)<<94
    agent[0] |= UInt128(3)
    agent[0]&=valid_energy_flag
    (sim+i*8).store(agent)
    agent_amount-=UInt32(Bool(not valid_energy_flag))

def rest(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt128(0)-UInt128(energy>1)
    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy-1)&1023)<<94
    agent[0]&=valid_energy_flag
    (sim+i*8).store(agent)
    agent_amount-=UInt32(Bool(not valid_energy_flag))

def deep_sleep(sleep_ticks: Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    pass #en -5

def talk_to(dr:Int, message: UInt128, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    energy = sim[i*8]<<24>>118
    valid_energy_flag=UInt128(0)-UInt128(energy>2)
    agent_space_flag=UInt128(0)-UInt128(Int((sim[(i*8+Int(lookup[dr]))&16777215]&3)==1))

    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= ((energy-2)&1023)<<94
    agent[0]&=valid_energy_flag
    (sim+i*8).store(agent)

    sim[i*8+Int(lookup[dr])&16777215]&=(~(255<<62)|~valid_energy_flag|~agent_space_flag)
    sim[i*8+Int(lookup[dr])&16777215]|=(((message<<62)&(255<<62))&valid_energy_flag&agent_space_flag)
    agent_amount-=UInt32(Bool(not valid_energy_flag))

def give_energy(dr:Int, amount: Int8, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin], mut agent_amount: UInt32):
    energy = sim[i*8]<<24>>118
    comptime lookup = SIMD[DType.int16, 8](-4104, -4096, -4088, -8, 8, 4088, 4096, 4104)
    valid_energy_flag=UInt128(0)-UInt128(energy>UInt128(amount))
    empty_space_flag=UInt128(0)-UInt128(Int((sim[(i*8+Int(lookup[dr]))&16777215]<<126>>126)==0))
    agent = (sim+i*8).load[width=1]()
    agent[0] &= ~(1023<<94)
    agent[0] |= (energy-UInt128(amount))<<94
    sim[(i*8+Int(lookup[dr]))&16777215]
    (sim+i*8).store(agent)


def jmp(dist:UInt128, dir:UInt128, am_cond:UInt128,first_not:UInt128,second_not:UInt128,all_cond: UInt128, mut sim: UnsafePointer[UInt128, MutExternalOrigin]) -> Int:
    var variable: UInt128
    comptime lookup = SIMD[DType.int16, 16](
    for cond in range(am_cond):
        variable = 

    return 5

def stop(i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass

def set_flag(flag_i: Int, value: UInt8, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]):
    pass

def get_flag(flag_i: Int, i: Int, mut sim: UnsafePointer[UInt128, MutExternalOrigin]) -> UInt8:
    return UInt8(0)


def step_interpretate():
    pass

def full_world(empty: Bool, mut sim: UnsafePointer[UInt128, MutExternalOrigin], agents_amount: UInt32):
    var ag_am = agents_amount&16777215
    



def main():
    var wh = 4096
    var ww = wh
    var ag_size_specs = 1
    var ag_size_mind = 7
    var sim = alloc[UInt128](wh*ww*(ag_size_specs+ag_size_mind))


    # Таблица длин команд в нибблах (16 значений для 16 возможных опкодов)
    # Индексы: 0:stop, 1:move, 2:ph, 3:eat, 4:atck, 5:div, 6:rest, 7:sleep, 
    #          8:talk, 9:give, 10:jmp, 11:set_f, 12:get_f, 13:add, 14:sub, 15:empty
    comptime cmd_lengths = SIMD[DType.uint8, 16](
        1,  # 0000 - stop (1 ниббл)
        2,  # 0001 - move (2 ниббла)
        1,  # 0010 - photosyntez (1 ниббл)
        2,  # 0011 - eat (2 ниббла)
        2,  # 0100 - attack (2 ниббла)
        2,  # 0101 - divide (2 ниббла)
        1,  # 0110 - rest (1 ниббл)
        2,  # 0111 - deep_sleep (2 ниббла)
        4,  # 1000 - talk_to (4 ниббла)
        4,  # 1001 - give_energy (4 ниббла)
        16, # 1010 - JMP (16 нибблов)
        4,  # 1011 - set_flag (4 ниббла)
        4,  # 1100 - get_flag (пока 4, хоть и удаляешь)
        4,  # 1101 - add (4 ниббла)
        4,  # 1110 - sub (4 ниббла)
        1   # 1111 - резерев (1 ниббл)
    )


    var Adam = SIMD[DType.uint128, 8](138649284399963717789195174913,0,0,0,0,0,0,0)
    var BAdam = SIMD[DType.uint128, 8](138649284399963717789195174913,0,0,0,0,0,0,0)
    var count_ag: UInt32=2
    sim.store(Adam)
    (sim+8).store(BAdam)
    print_agent(sim[0])
    print_bin(sim[0])
    talk_to(4,255,0,sim,count_ag)
    print_agent(sim[8])
    print_bin(sim[8])
    print(count_ag)