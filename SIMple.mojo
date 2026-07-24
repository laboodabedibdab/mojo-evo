from std.collections import List
from std.time import perf_counter

@always_inline
def type_value(t: UInt16,v: UInt16,pars: List[UInt16]) -> UInt16:
    if t>127:
        return v
    else:
        return pars[v%UInt16(len(pars))]

@always_inline
def randomize(mut seed: UInt16) -> UInt16:
    seed^=seed<<7
    seed^=seed>>9
    seed^=seed<<8
    return seed

struct Agent(Copyable):
    var x: UInt16
    var y: UInt16
    var pos: UInt16
    var genome: List[SIMD[DType.uint16, 10]]
    var command_pointer: Int
    var vars_cont:SIMD[DType.uint16, 4]
    var vars:SIMD[DType.uint16, 4]
    var age:UInt16
    var deep_sleep_ticks:UInt8
    var direction:UInt8

    def __init__(out self, x: UInt16, y: UInt16):
        self.x = x&255
        self.y = y&255
        self.pos=y*256+x
        self.age = 0
        self.genome = List[SIMD[DType.uint16, 10]]()
        self.vars_cont = SIMD[DType.uint16, 4]()
        self.vars = SIMD[DType.uint16, 4]()
        self.command_pointer = 0
        self.deep_sleep_ticks = 0
        self.direction = 0

    def add_command(mut self, cmd: SIMD[DType.uint16, 10]):
        self.genome.append(cmd)
 
    def mutate(mut self, mut r: UInt16):
        if not len(self.genome):
            return
        if (randomize(r)&255)>127:
            self.genome[Int(randomize(r))%len(self.genome)][Int(randomize(r)%10)]+=1
        else:
            self.genome[Int(randomize(r))%len(self.genome)][Int(randomize(r)%10)]-=1

    def execute_current_command(mut self, i: UInt, mut genoms_and_other: List[Agent],mut grid: UnsafePointer[UInt16, MutExternalOrigin],mut energys: List[UInt16],mut org: Dict[UInt16, UInt16]) raises -> Bool:
        self.age+=1
        if self.command_pointer >= len(self.genome):
            self.command_pointer = 0
        var pars = [energys[i], self.x, self.y, self.age, UInt16(self.direction), UInt16(self.vars[0]), UInt16(self.vars[1]), UInt16(self.vars[2]), UInt16(self.vars[3])]
        for pi in range(8):
            dn=9
            for pj in range(8):
                delta_dist = Int16(pj)*SIMD[DType.int16,8](-1,0,1,-1,1,-1,0,1)[pi]+(Int16(256*pj)*SIMD[DType.int16,8](1,1,1,0,0,-1,-1,-1)[pi])
                obj_check_pos = grid[Int16(self.pos)+delta_dist]
                if obj_check_pos:
                    dn = pj
                    break
            pars.append(UInt16(dn))
        #print(len(pars))

        if self.age>=UInt16(-2) or energys[i]>=2048:
            #die then exit
            remove_agent(genoms_and_other, grid, energys, Int(i), self.pos)
            return False

        energys[i] = min(energys[i],2048)

        if self.deep_sleep_ticks>0:
            self.deep_sleep_ticks-=1
            return False


        var cmd = self.genome[self.command_pointer]
        nc = cmd[0]%13
        if nc == 0:
            #STOP
            self.command_pointer = 0
            energys[i]-=1
        elif nc == 1:
            #MOVE
            var dx = SIMD[DType.int16,8](-1,0,1,1,1,0,-1,-1)[Int(self.direction)]
            var dy = SIMD[DType.int16,8](1,1,1,0,-1,-1,-1,0)[Int(self.direction)]*256
            energys[i]-=2
            newpos = UInt16(Int16(self.pos)+dx+dy)
            if not (grid[newpos] or (org.__contains__(UInt16(newpos)))):
                grid[newpos] = grid[self.pos]
                grid[self.pos]=0
                self.pos=UInt16(newpos)
        elif nc == 2:
            #PHOTOSYNTEZ
            energys[i]+=1
        elif nc == 3:
            #ATTACK
            var dx = SIMD[DType.int16,8](-1,0,1,1,1,0,-1,-1)[Int(self.direction)]
            var dy = SIMD[DType.int16,8](1,1,1,0,-1,-1,-1,0)[Int(self.direction)]*256
            attack_pos = UInt16(Int16(self.pos)+dx+dy)
            if grid[attack_pos]:
                energys[i] -= 10
                org[attack_pos] = energys[grid[attack_pos]-1]
                remove_agent(genoms_and_other, grid, energys, Int(grid[attack_pos])-1, attack_pos)
            energys[i] -= 3

        elif nc == 4:
            #EAT т
            var dx = SIMD[DType.int16,8](-1,0,1,1,1,0,-1,-1)[Int(self.direction)]
            var dy = SIMD[DType.int16,8](1,1,1,0,-1,-1,-1,0)[Int(self.direction)]*256
            var orgcell = org.find(UInt16(Int16(self.pos)+dx+dy))
            if orgcell:
                energys[i] += orgcell.or_else(0)
            else:
                
                energys[i] -= 2
        elif nc == 5:
            #DUPLICATE
            var dx = SIMD[DType.int16,8](-1,0,1,1,1,0,-1,-1)[Int(self.direction)]
            var dy = SIMD[DType.int16,8](1,1,1,0,-1,-1,-1,0)[Int(self.direction)]*256
            energys[i]//=2
            duplicate_pos=UInt(Int16(self.pos)+dx+dy)
            if not (grid[duplicate_pos] or (org.__contains__(UInt16(duplicate_pos)))):
                add_agent(genoms_and_other, grid, energys, self, UInt16(duplicate_pos), energys[i])

        elif nc == 6:
            #PASS
            energys[i]-=1
        elif nc == 7:
            #DEEP SLEEP
            energys[i]-=3
            self.deep_sleep_ticks = UInt8(type_value(cmd[1], cmd[2], pars)&63)
            
        elif nc == 8:
            #TALK
            var dx = SIMD[DType.int16,8](-1,0,1,1,1,0,-1,-1)[Int(self.direction)]
            var dy = SIMD[DType.int16,8](1,1,1,0,-1,-1,-1,0)[Int(self.direction)]*256
            newpos = UInt16(Int16(self.pos)+dx+dy)
            if grid[newpos]:
                if grid[newpos]<len(energys):
                    genoms_and_other[grid[newpos]-1].vars[Int(type_value(cmd[1], cmd[2], pars))&3]=type_value(cmd[3], cmd[4], pars)
                else:
                    print()
                    print(143)
                    print(len(genoms_and_other))
                    print(len(energys))
                    for pi in range(65535,0,-1):
                        if grid[pi]:
                            print(pi)
                            print(grid[pi])
                            break
                    print()
                    return True
        elif nc == 9:
            #TURN
            self.direction=UInt8(type_value(cmd[1], cmd[2], pars)&7)
            energys[i]-=1
        elif nc == 10:
            #GIVE_ENERGY
            var dx = SIMD[DType.int16,8](-1,0,1,1,1,0,-1,-1)[Int(self.direction)]
            var dy = SIMD[DType.int16,8](1,1,1,0,-1,-1,-1,0)[Int(self.direction)]*256
            newpos = UInt16(Int16(self.pos)+dx+dy)
            if not energys[i]:
                return False
            add_energy = UInt16(type_value(cmd[1], cmd[2], pars))%energys[i]
            if org.find(newpos):
                org[newpos]+= add_energy
                return False
            else:
                if grid[newpos]:
                    if grid[newpos]<len(energys):
                        energys[grid[newpos]-1] += add_energy
                    else:
                        print()
                        print(160)
                        print(len(genoms_and_other))
                        print(len(energys))
                        for pi in range(65535,0,-1):
                            if grid[pi]:
                                print(pi)
                                print(grid[pi])
                                break
                        print()
                        return True
                else:
                    org[newpos] = add_energy
            energys[i]-=add_energy
        elif nc == 11:
            #JUMP
            if not len(self.genome):
                return False
            dir_jmp=cmd[1]&255
            dist_jmp=cmd[2]
            
            fc = type_value(cmd[5],cmd[6],pars)
            sc = type_value(cmd[7],cmd[8],pars)
            if [fc>sc,fc<sc,fc==sc,fc!=sc][cmd[9]&3]:
                if dir_jmp>127:
                    self.command_pointer+=Int(dist_jmp)
                else:
                    self.command_pointer-=Int(dist_jmp)
                self.command_pointer%=len(self.genome)
        elif nc == 12:
            #VAR CHANGE
            chin = Int(cmd[1]&3)
            var_cont = self.vars_cont[chin]
            val_chng = type_value(cmd[3],cmd[4],pars)
            div = UInt16(-1)
            if val_chng!=0:
                div=var_cont/val_chng
            self.vars_cont[chin] = [var_cont+val_chng, var_cont-val_chng, var_cont*val_chng, div][cmd[2]&3]
        return False
        # stop (1 ниббл) команда
        # move (2 ниббла) команда направление
        # photosyntez (1 ниббл) команда
        # eat (2 ниббла) команда направление
        # attack (2 ниббла) команда направление
        # divide (2 ниббла) команда направление
        # rest (1 ниббл) команда
        # deep_sleep (2 ниббла) команда номер
        # talk_to (4 ниббла) команда направление что сказать
        # give_energy (4 ниббла) команда направление сколько дать
        # JMP (16 нибблов) команда куда насколько переменная знак_сравнения число 
        # set_flag (4 ниббла) команда номер флага число
        # get_flag (пока 4, хоть и удаляешь) похер
        # add (4 ниббла) похер?
        # sub (4 ниббла) похер?
        # резерев (1 ниббл) похер





#var genoms_and_other : List[Agent]
#var positions: List[SIMD[DType.uint16,2]]
#var energys: List[UInt16]
#var org: Dict[Tuple[UInt16, UInt16], UInt16]


def add_agent(mut genoms_and_other: List[Agent],mut grid: UnsafePointer[UInt16, MutExternalOrigin],mut energys: List[UInt16],mut genom_and_other_s: Agent, pos: UInt16, energy: UInt16):
    genoms_and_other.append(genom_and_other_s.copy())
    grid[pos]=UInt16(len(genoms_and_other))
    energys.append(energy)
    
def remove_agent(mut genoms_and_other: List[Agent],mut grid: UnsafePointer[UInt16, MutExternalOrigin],mut energys: List[UInt16], index: Int, pos: UInt16):
    print("Агент", index, "сдох, помечаю на удаление")
    print("До:")
    print("Количество мозгов:"+String(len(genoms_and_other)))
    print("Количество энергий:"+String(len(energys)))
    maximum_now:UInt16=0
    for pi in range(65535,0,-1):
        if grid[pi]>maximum_now:
            maximum_now=grid[pi]
    for pi in range(65535,0,-1):
        if grid[pi]:
            print("Позиция последнего:"+String(pi)+String(grid[pi]))
            break
    print("Максимальный индекс:"+String(maximum_now))
    print()
    print("После:")
    print(genoms_and_other[len(genoms_and_other)-1].pos)
    print(grid[genoms_and_other[len(genoms_and_other)-1].pos])
    grid[genoms_and_other[len(genoms_and_other)-1].pos]=len(genoms_and_other)-1
    genoms_and_other.swap_elements(index,len(genoms_and_other) - 1)
    grid[pos]=0
    #UInt16(index+1)
    energys.swap_elements(index,len(energys) - 1)
    _ = genoms_and_other.pop()
    _ = energys.pop()
    print("Количество мозгов:"+String(len(genoms_and_other)))
    print("Количество энергий:"+String(len(energys)))
    maximum_now=0
    for pi in range(65535,0,-1):
        if grid[pi]>maximum_now:
            maximum_now=grid[pi]
    for pi in range(65535,0,-1):
        if grid[pi]:
            print("Позиция последнего:"+String(pi))
            break
    print("Максимальный индекс:"+String(maximum_now))
    print()

def step(mut r:UInt16, mut genoms_and_other: List[Agent],mut grid: UnsafePointer[UInt16, MutExternalOrigin],mut energys: List[UInt16],mut org: Dict[UInt16, UInt16]) raises:
    #genoms_and_other_copy = genoms_and_other.copy()
    i=0
    while i < (len(genoms_and_other)-1):
        var item = genoms_and_other[i].copy()
        if item.execute_current_command(UInt(i), genoms_and_other, grid, energys, org):
            break
        if UInt16(0)==randomize(r)%255:
            item.mutate(r)
        genoms_and_other[i]=item^
        i+=1



def main() raises:
    var seed:UInt16 = 12345

    var genoms_and_other = List[Agent]()
    var grid = alloc[UInt16](256*256)
    var energys = List[UInt16]()
    var org = Dict[UInt16, UInt16]()
    
    for a in range(40000):
        adam = Agent(x=UInt16(a>>8),y=UInt16(a&255))
        for _ in range(10):
            adam.add_command(SIMD[DType.uint16, 10](randomize(seed),randomize(seed),randomize(seed),randomize(seed),randomize(seed),randomize(seed),randomize(seed),randomize(seed),randomize(seed),randomize(seed)))
        add_agent(genoms_and_other, grid, energys, adam, UInt16(a), 256)

    

    print("Filled")
    
    ftc=perf_counter()
    # for i in range(len(genoms_and_other)):
    #     var item = genoms_and_other[i].copy()
    #     item.execute_current_command(i, genoms_and_other, grid, energys, org)
    #     if UInt16(0)==randomize(seed)%255:
    #         item.mutate(seed)
    #     genoms_and_other[i]=item^

    step(seed, genoms_and_other, grid, energys, org)

    #var item = genoms_and_other[0].copy()
    #item.execute_current_command(0, genoms_and_other, positions, energys, org)
    #if UInt16(0)==randomize(seed)%255:
    #    item.mutate(seed)
    #genoms_and_other[0]=item^
    stc=perf_counter()
    print()
    print(genoms_and_other[len(genoms_and_other)//2].age)
    print(grid[len(genoms_and_other)//2])
    print(energys[len(genoms_and_other)//2])
    print(len(genoms_and_other))
    print(len(energys))
    print()
    print(1/(stc-ftc))
    