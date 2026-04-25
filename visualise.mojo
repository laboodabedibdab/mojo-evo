from std.random import rand, randint, seed
from std import time



struct Model:
	var weights: UnsafePointer[Float16, MutExternalOrigin]
	var bias: UnsafePointer[Float16, MutExternalOrigin]

	def forward(read self, inputs: SIMD[DType.float16, 16]) -> SIMD[DType.float16, 16]:
		var res: SIMD[DType.float16, 16] = inputs
		var res_copy = res.copy()
		for i in range(8):
			for j in range(16):
				res_copy[j] = (res * self.weights.load[dtype=DType.float16, width=16](i*16+j*16)).reduce_add()
			res = res_copy + self.bias.load[dtype=DType.float16, width=16](i*16)
		return res
	def __init__(out self, weights: List[List[List[Float16]]], bias: List[List[Float16]]):
		self.weights = alloc[Float16](16 * 16 * 8)
		self.bias = alloc[Float16](16 * 8)
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
#	try:
#		var column_str = input('Столбец: ')
#		var column = Int(column_str)
#
#		var stroke_str = input('Строка: ')
#		var stroke = Int(stroke_str)
#
#		while True:
#			print(a[column + stroke*WIDTH - (1+WIDTH)])
#			column_str = input('Столбец: ')
#			column = Int(column_str)
#
#			stroke_str = input('Строка: ')
#			stroke = Int(stroke_str)
#	finally:
#		a.free()
	mm = Model([[[0.5]]],[[0.5]])
	var result = mm.forward(SIMD[DType.float16, 16](0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15))
	for el_i in range(16):
		print(result[el_i])