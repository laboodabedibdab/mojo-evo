from std.random import rand, randint, seed
from std import time
from std.math import iota
from std.memory import bitcast
from std.sys.intrinsics import llvm_intrinsic




def get_tsc() -> UInt64:
    return llvm_intrinsic["llvm.x86.rdtsc", UInt64]()




struct Model:
	var weights: UnsafePointer[Float16, MutExternalOrigin]
	var bias: UnsafePointer[Float16, MutExternalOrigin]
	var rand_multiply_matrix_weights: UnsafePointer[Float16, MutExternalOrigin]
	var rand_multiply_matrix_bias: UnsafePointer[Float16, MutExternalOrigin]



	def forward(read self, inputs: SIMD[DType.float16, 16]) -> SIMD[DType.float16, 16]:
		var res: SIMD[DType.float16, 16] = inputs
		var res_copy = res.copy()
		
		for i in range(8):
			for j in range(16):
				res_copy[j] = (res * self.weights.load[dtype=DType.float16, width=16](i*16+j*16)).reduce_add()
			res = res_copy + self.bias.load[dtype=DType.float16, width=16](i*16)
		return res

	def mutate(mut self, a: Float16, b: Float64):

		#var rand_multiply_matrix_weights = alloc[Float16](16 * 16 * 8)
		#var rand_multiply_matrix_bias = alloc[Float16](16 * 8)
		var rand_simd_weights = bitcast[DType.int16, 16*16*8](get_tsc())
		var rand_simd_bias = bitcast[DType.int16, 16*8](get_tsc())
		
		var bits_weights = (rand_simd_weights & 0x03FF) | 0x3C00
		var bits_bias = (rand_simd_bias & 0x03FF) | 0x3C00
		
		
		#rand[DType.float16](self.rand_multiply_matrix_weights, 16 * 16 * 8, min=-1*b, max=b)
		#rand[DType.float16](self.rand_multiply_matrix_bias, 16 * 8, min=-1*b, max=b)
		#rand_multiply_matrix_
		#rand_multiply_matrix_


		#rand_simd_weights = self.weights.load[dtype=DType.float16, width=16*16*8]()
		#rand_simd_bias = self.bias.load[dtype=DType.float16, width=16*8]()

		rand_simd_weights ^= rand_simd_weights << 13
		rand_simd_weights ^= rand_simd_weights >> 17
		rand_simd_weights ^= rand_simd_weights << 5
		
		rand_simd_bias ^= rand_simd_bias << 13
		rand_simd_bias ^= rand_simd_bias >> 17
		rand_simd_bias ^= rand_simd_bias << 5
		
		var float_rand_simd_weights = (bitcast[DType.float16](bits_weights) - 1.5) * (2 * a)
		var float_rand_simd_bias = (bitcast[DType.float16](bits_bias) - 1.5) * (2 * a)
		

		orig_simd_weights = self.weights.load[dtype=DType.float16, width=16*16*8]()
		orig_simd_bias = self.bias.load[dtype=DType.float16, width=16*8]()
		float_rand_simd_weights=(float_rand_simd_weights-orig_simd_weights)*a+orig_simd_weights
		float_rand_simd_bias=(float_rand_simd_bias-orig_simd_bias)*a+orig_simd_bias
		self.weights.store(float_rand_simd_weights)
		self.bias.store(float_rand_simd_bias)
		




	def free_all(mut self):
		self.weights.free()
		self.bias.free()

		self.rand_multiply_matrix_weights.free()
		self.rand_multiply_matrix_bias.free()



	def __init__(out self, weights: List[List[List[Float16]]], bias: List[List[Float16]]):
		self.weights = alloc[Float16](16 * 16 * 8)
		self.bias = alloc[Float16](16 * 8)
		self.rand_multiply_matrix_weights = alloc[Float16](16 * 16 * 8)
		self.rand_multiply_matrix_bias = alloc[Float16](16 * 8)

		#var ws = len(weights)
		#var lr = len(weights[0])
		#var nr = len(weights[0][0])
		#var bws = len(weights)
		#var blr = len(weights[0])
		#var i = 0
		#var bi = 0
		rand[DType.float16](self.weights, 16 * 16 * 8, min=-0.2, max=0.2)
		rand[DType.float16](self.bias, 16 * 8, min=-0.2, max=0.2)
#		for layer_i in range(ws):
#			for neuron_i in range(lr):
#				for w_i in range(nr):
#					i = layer_i * (lr*nr) + neuron_i * nr + w_i
#					(self.weights+i).init_pointee_copy(weights[layer_i][neuron_i][w_i])
#		for blayer_i in range(bws):
#			for bneuron_i in range(blr):
#				bi = blayer_i * blr + bneuron_i
#				(self.bias+bi).init_pointee_copy(bias[blayer_i][bneuron_i])




def main() raises:
#	seed(Int(time.perf_counter()))
#	comptime WIDTH = 1000
#	comptime HEIGHT = 1000
#	var a = alloc[UInt8](1_000_000)
#	for i in range(1_000_000):
#		(a+i).init_pointee_copy(UInt8(i>994999))
	print(get_tsc())
	mm = Model([[[0.5]]],[[0.5]])
	var result = SIMD[DType.float16, 16](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
	var c = 0
	var a_str = input()
	var a = Float16(Float64(a_str))
	var start = time.perf_counter()
	#while abs(result.reduce_add()-10)!=0:
		#print(result.reduce_add())
	mm.mutate(a,2)
		#c+=1
		#result = mm.forward(SIMD[DType.float16, 16](0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15))
	var stop = time.perf_counter()
	print("MUTATED!")
	
	print(c)
	print(stop-start)

	result = mm.forward(SIMD[DType.float16, 16](0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15))
	print(result.reduce_add())
	mm.free_all()
