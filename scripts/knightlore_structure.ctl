# Knight Lore: which bytes are code, which are data, and what things are called.
#
# This file is GENERATED, not hand-written. Regenerate it with:
#
#     python scripts/build_knightlore.py --from-skool PATH/TO/knightlore.skool
#
# and do not edit it directly -- put what you learn in
# scripts/knightlore_annotations.ctl, which is layered on top and survives.
#
# Provenance. The code map here is derived from the Knight Lore disassembly by
# tcdev (2017), converted to SkoolKit form by Michael R. Cook (2019). Only the
# factual layer is taken: block boundaries, the code/data split, sub-block
# lengths and the labels. None of their prose is copied -- the commentary in
# this disassembly is our own. Neither of those works carries a licence, so
# they are treated as reference and credit only.
#
# The map is not taken on trust. Every byte it describes is disassembled and
# reassembled on each build and compared with the snapshot, so a boundary in
# the wrong place shows up as a mismatch rather than as quiet nonsense.
#
# Knight Lore is copyright (c) 1984 Ultimate Play the Game, designed and
# written by Tim and Chris Stamper. Nothing here reproduces its bytes.

@ $6108 start
@ $6108 org
b $6108
@ $6108 label=font
B $6108,8,h8
B $6110,8,h8
B $6118,8,h8
B $6120,8,h8
B $6128,8,h8
B $6130,8,h8
B $6138,8,h8
B $6140,8,h8
B $6148,8,h8
B $6150,8,h8
B $6158,8,h8
B $6160,8,h8
B $6168,8,h8
B $6170,8,h8
B $6178,8,h8
B $6180,8,h8
B $6188,8,h8
B $6190,8,h8
B $6198,8,h8
B $61A0,8,h8
B $61A8,8,h8
B $61B0,8,h8
B $61B8,8,h8
B $61C0,8,h8
B $61C8,8,h8
B $61D0,8,h8
B $61D8,8,h8
B $61E0,8,h8
B $61E8,8,h8
B $61F0,8,h8
B $61F8,8,h8
B $6200,8,h8
B $6208,8,h8
B $6210,8,h8
B $6218,8,h8
B $6220,8,h8
B $6228,8,h8
B $6230,8,h8
B $6238,8,h8
B $6240,8,h8
b $6248
@ $6248 label=room_size_tbl
B $6248,3,h3
B $624B,3,h3
B $624E,3,h3
b $6251
@ $6251 label=location_tbl
B $6251,3,h3
B $6254,23,h11,h8,h4
B $626B,3,h3
B $626E,18,h11,h7
B $6280,3,h3
B $6283,4,h4
B $6287,3,h3
B $628A,24,h11,h8,h5
B $62A2,3,h3
B $62A5,17,h10,h7
B $62B6,3,h3
B $62B9,24,h10,h8,h6
B $62D1,3,h3
B $62D4,9,h9
B $62DD,3,h3
B $62E0,23,h10,h8,h5
B $62F7,3,h3
B $62FA,4,h4
B $62FE,3,h3
B $6301,21,h10,h8,h3
B $6316,3,h3
B $6319,4,h4
B $631D,3,h3
B $6320,9,h9
B $6329,3,h3
B $632C,26,h11,h8,h7
B $6346,3,h3
B $6349,22,h11,h8,h3
B $635F,3,h3
B $6362,22,h22
B $6378,3,h3
B $637B,24,h24
B $6393,3,h3
B $6396,15,h15
B $63A5,3,h3
B $63A8,25,h25
B $63C1,3,h3
B $63C4,21,h21
B $63D9,3,h3
B $63DC,16,h16
B $63EC,3,h3
B $63EF,26,h26
B $6409,3,h3
B $640C,24,h24
B $6424,3,h3
B $6427,22,h22
B $643D,3,h3
B $6440,13,h13
B $644D,3,h3
B $6450,14,h14
B $645E,3,h3
B $6461,21,h21
B $6476,3,h3
B $6479,15,h15
B $6488,3,h3
B $648B,4,h4
B $648F,3,h3
B $6492,20,h20
B $64A6,3,h3
B $64A9,22,h22
B $64BF,3,h3
B $64C2,11,h11
B $64CD,3,h3
B $64D0,23,h23
B $64E7,3,h3
B $64EA,23,h23
B $6501,3,h3
B $6504,17,h17
B $6515,3,h3
B $6518,21,h21
B $652D,3,h3
B $6530,19,h19
B $6543,3,h3
B $6546,25,h25
B $655F,3,h3
B $6562,5,h5
B $6567,3,h3
B $656A,27,h27
B $6585,3,h3
B $6588,26,h26
B $65A2,3,h3
B $65A5,4,h4
B $65A9,3,h3
B $65AC,21,h21
B $65C1,3,h3
B $65C4,19,h19
B $65D7,3,h3
B $65DA,20,h20
B $65EE,3,h3
B $65F1,18,h18
B $6603,3,h3
B $6606,9,h9
B $660F,3,h3
B $6612,16,h16
B $6622,3,h3
B $6625,4,h4
B $6629,3,h3
B $662C,16,h16
B $663C,3,h3
B $663F,16,h16
B $664F,3,h3
B $6652,23,h23
B $6669,3,h3
B $666C,3,h3
B $666F,3,h3
B $6672,15,h15
B $6681,3,h3
B $6684,22,h22
B $669A,3,h3
B $669D,21,h21
B $66B2,3,h3
B $66B5,5,h5
B $66BA,3,h3
B $66BD,18,h18
B $66CF,3,h3
B $66D2,22,h22
B $66E8,3,h3
B $66EB,12,h12
B $66F7,3,h3
B $66FA,20,h20
B $670E,3,h3
B $6711,5,h5
B $6716,3,h3
B $6719,23,h23
B $6730,3,h3
B $6733,20,h20
B $6747,3,h3
B $674A,20,h20
B $675E,3,h3
B $6761,3,h3
B $6764,3,h3
B $6767,21,h21
B $677C,3,h3
B $677F,23,h23
B $6796,3,h3
B $6799,9,h9
B $67A2,3,h3
B $67A5,22,h22
B $67BB,3,h3
B $67BE,17,h17
B $67CF,3,h3
B $67D2,18,h18
B $67E4,3,h3
B $67E7,22,h22
B $67FD,3,h3
B $6800,4,h4
B $6804,3,h3
B $6807,23,h23
B $681E,3,h3
B $6821,24,h24
B $6839,3,h3
B $683C,10,h10
B $6846,3,h3
B $6849,3,h3
B $684C,3,h3
B $684F,18,h18
B $6861,3,h3
B $6864,14,h14
B $6872,3,h3
B $6875,24,h24
B $688D,3,h3
B $6890,21,h21
B $68A5,3,h3
B $68A8,22,h22
B $68BE,3,h3
B $68C1,26,h26
B $68DB,3,h3
B $68DE,3,h3
B $68E1,3,h3
B $68E4,22,h22
B $68FA,3,h3
B $68FD,22,h22
B $6913,3,h3
B $6916,4,h4
B $691A,3,h3
B $691D,12,h12
B $6929,3,h3
B $692C,4,h4
B $6930,3,h3
B $6933,17,h17
B $6944,3,h3
B $6947,12,h12
B $6953,3,h3
B $6956,23,h23
B $696D,3,h3
B $6970,9,h9
B $6979,3,h3
B $697C,27,h27
B $6997,3,h3
B $699A,18,h18
B $69AC,3,h3
B $69AF,9,h9
B $69B8,3,h3
B $69BB,8,h8
B $69C3,3,h3
B $69C6,23,h23
B $69DD,3,h3
B $69E0,15,h15
B $69EF,3,h3
B $69F2,19,h19
B $6A05,3,h3
B $6A08,16,h16
B $6A18,3,h3
B $6A1B,19,h19
B $6A2E,4,h4
B $6A32,11,h11
B $6A3D,3,h3
B $6A40,4,h4
B $6A44,3,h3
B $6A47,24,h24
B $6A5F,3,h3
B $6A62,3,h3
B $6A65,3,h3
B $6A68,20,h20
B $6A7C,3,h3
B $6A7F,15,h15
B $6A8E,3,h3
B $6A91,20,h20
B $6AA5,3,h3
B $6AA8,25,h25
B $6AC1,3,h3
B $6AC4,5,h5
B $6AC9,3,h3
B $6ACC,15,h15
B $6ADB,3,h3
B $6ADE,20,h20
B $6AF2,3,h3
B $6AF5,4,h4
B $6AF9,3,h3
B $6AFC,18,h18
B $6B0E,3,h3
B $6B11,3,h3
B $6B14,3,h3
B $6B17,25,h25
B $6B30,3,h3
B $6B33,8,h8
B $6B3B,3,h3
B $6B3E,4,h4
B $6B42,3,h3
B $6B45,21,h21
B $6B5A,3,h3
B $6B5D,17,h17
B $6B6E,3,h3
B $6B71,19,h19
B $6B84,3,h3
B $6B87,5,h5
B $6B8C,3,h3
B $6B8F,17,h17
B $6BA0,3,h3
B $6BA3,15,h15
B $6BB2,3,h3
B $6BB5,16,h16
B $6BC5,3,h3
B $6BC8,9,h9
b $6BD1
@ $6BD1 label=block_type_tbl
W $6BD1,2,h2
W $6BD3,2,h2
W $6BD5,2,h2
W $6BD7,2,h2
W $6BD9,2,h2
W $6BDB,2,h2
W $6BDD,2,h2
W $6BDF,2,h2
W $6BE1,2,h2
W $6BE3,2,h2
W $6BE5,2,h2
W $6BE7,2,h2
W $6BE9,2,h2
W $6BEB,2,h2
W $6BED,2,h2
W $6BEF,2,h2
W $6BF1,2,h2
W $6BF3,2,h2
W $6BF5,2,h2
W $6BF7,2,h2
W $6BF9,2,h2
W $6BFB,2,h2
W $6BFD,2,h2
W $6BFF,2,h2
W $6C01,2,h2
W $6C03,2,h2
W $6C05,2,h2
W $6C07,2,h2
W $6C09,2,h2
b $6C0B
@ $6C0B label=block
B $6C0B,7,h7
b $6C12
@ $6C12 label=block_high
B $6C12,7,h7
b $6C19
@ $6C19 label=block_ew
B $6C19,7,h7
b $6C20
@ $6C20 label=block_ns
B $6C20,7,h7
b $6C27
@ $6C27 label=moveable_block
B $6C27,7,h7
b $6C2E
@ $6C2E label=dropping_block
B $6C2E,7,h7
b $6C35
@ $6C35 label=collapsing_block
B $6C35,7,h7
b $6C3C
@ $6C3C label=fire
B $6C3C,7,h7
b $6C43
@ $6C43 label=ball_ud_y
B $6C43,7,h7
b $6C4A
@ $6C4A label=ball_ud_xy
B $6C4A,7,h7
b $6C51
@ $6C51 label=ball_ud
B $6C51,7,h7
b $6C58
@ $6C58 label=ball_ud_x
B $6C58,7,h7
b $6C5F
@ $6C5F label=ball_bounce
B $6C5F,7,h7
b $6C66
@ $6C66 label=rock
B $6C66,7,h7
b $6C6D
@ $6C6D label=gargoyle
B $6C6D,7,h7
b $6C74
@ $6C74 label=spike
B $6C74,7,h7
b $6C7B
@ $6C7B label=spike_high
B $6C7B,7,h7
b $6C82
@ $6C82 label=spike_ball_fall
B $6C82,7,h7
b $6C89
@ $6C89 label=spike_ball_high_fall
B $6C89,7,h7
b $6C90
@ $6C90 label=chest
B $6C90,7,h7
b $6C97
@ $6C97 label=table
B $6C97,7,h7
b $6C9E
@ $6C9E label=guard_ew
B $6C9E,13,h13
b $6CAB
@ $6CAB label=guard_square
B $6CAB,13,h13
b $6CB8
@ $6CB8 label=ghost
B $6CB8,7,h7
b $6CBF
@ $6CBF label=fire_ns
B $6CBF,7,h7
b $6CC6
@ $6CC6 label=fire_ew
B $6CC6,7,h7
b $6CCD
@ $6CCD label=repel_spell
B $6CCD,7,h7
b $6CD4
@ $6CD4 label=gate_ud_1
B $6CD4,7,h7
b $6CDB
@ $6CDB label=gate_ud_2
B $6CDB,7,h7
b $6CE2
@ $6CE2 label=background_type_tbl
W $6CE2,2,h2
W $6CE4,2,h2
W $6CE6,2,h2
W $6CE8,2,h2
W $6CEA,2,h2
W $6CEC,2,h2
W $6CEE,2,h2
W $6CF0,2,h2
W $6CF2,2,h2
W $6CF4,2,h2
W $6CF6,2,h2
W $6CF8,2,h2
W $6CFA,2,h2
W $6CFC,2,h2
W $6CFE,2,h2
W $6D00,2,h2
W $6D02,2,h2
W $6D04,2,h2
W $6D06,2,h2
W $6D08,2,h2
W $6D0A,2,h2
W $6D0C,2,h2
W $6D0E,2,h2
W $6D10,2,h2
b $6D12
@ $6D12 label=arch_n
B $6D12,17,h8*2,h1
b $6D23
@ $6D23 label=arch_e
B $6D23,17,h8*2,h1
b $6D34
@ $6D34 label=high_arch_e
B $6D34,17,h8*2,h1
b $6D45
@ $6D45 label=arch_s
B $6D45,17,h8*2,h1
b $6D56
@ $6D56 label=high_arch_s
B $6D56,17,h8*2,h1
b $6D67
@ $6D67 label=arch_w
B $6D67,17,h8*2,h1
b $6D78
@ $6D78 label=tree_arch_n
B $6D78,17,h8*2,h1
b $6D89
@ $6D89 label=tree_arch_e
B $6D89,17,h8*2,h1
b $6D9A
@ $6D9A label=tree_arch_s
B $6D9A,17,h8*2,h1
b $6DAB
@ $6DAB label=tree_arch_w
B $6DAB,17,h8*2,h1
b $6DBC
@ $6DBC label=gate_n
B $6DBC,9,h8,h1
b $6DC5
@ $6DC5 label=gate_e
B $6DC5,9,h8,h1
b $6DCE
@ $6DCE label=gate_s
B $6DCE,9,h8,h1
b $6DD7
@ $6DD7 label=gate_w
B $6DD7,9,h8,h1
b $6DE0
@ $6DE0 label=wall_size_1
B $6DE0,105,h8*13,h1
b $6E49
@ $6E49 label=wall_size_2
B $6E49,113,h8*14,h1
b $6EBA
@ $6EBA label=wall_size_3
B $6EBA,113,h8*14,h1
b $6F2B
@ $6F2B label=tree_room_size_1
B $6F2B,97,h8*12,h1
b $6F8C
@ $6F8C label=tree_filler_w
B $6F8C,17,h8*2,h1
b $6F9D
@ $6F9D label=tree_filler_n
B $6F9D,17,h8*2,h1
b $6FAE
@ $6FAE label=wizard
B $6FAE,17,h8*2,h1
b $6FBF
@ $6FBF label=cauldron
B $6FBF,17,h8*2,h1
b $6FD0
@ $6FD0 label=high_arch_e_base
B $6FD0,17,h8*2,h1
b $6FE1
@ $6FE1 label=high_arch_s_base
B $6FE1,17,h8*2,h1
b $6FF2
@ $6FF2 label=special_objs_tbl
B $6FF2,288,h9
b $7112
@ $7112 label=sprite_tbl
W $7112,376,h16*23,h8
b $728A
@ $728A label=spr_nul
B $728A,2,h2
b $728C
@ $728C label=spr_000
B $728C,188,h2,h8*23,h2
b $7348
@ $7348 label=spr_001
B $7348,188,h2,h8*23,h2
b $7404
@ $7404 label=spr_002
B $7404,226,h2,h8
b $74E6
@ $74E6 label=spr_003
B $74E6,202,h2,h8
b $75B0
@ $75B0 label=spr_004
B $75B0,140,h2,h8*17,h2
b $763C
@ $763C label=spr_005
B $763C,140,h2,h8*17,h2
b $76C8
@ $76C8 label=spr_006
B $76C8,116,h2,h8*14,h2
b $773C
@ $773C label=spr_007
B $773C,110,h2,h8*13,h4
b $77AA
@ $77AA label=spr_008
B $77AA,234,h2,h8
b $7894
@ $7894 label=spr_009
B $7894,146,h2,h8
b $7926
@ $7926 label=spr_010
B $7926,62,h2,h8*7,h4
b $7964
@ $7964 label=spr_011
B $7964,66,h2,h8
b $79A6
@ $79A6 label=spr_012
B $79A6,236,h2,h8*29,h2
b $7A92
@ $7A92 label=spr_013
B $7A92,200,h2,h8*24,h6
b $7B5A
@ $7B5A label=spr_014
B $7B5A,258,h2,h8
b $7C5C
@ $7C5C label=spr_015
B $7C5C,8,h2,h6
b $7C64
@ $7C64 label=spr_016
B $7C64,50,h2,h8
b $7C96
@ $7C96 label=spr_017
B $7C96,258,h2,h8
b $7D98
@ $7D98 label=filler
B $7D98,12,h12
b $7DA4
@ $7DA4 label=spr_018
B $7DA4,66,h2,h8
b $7DE6
@ $7DE6 label=spr_019
B $7DE6,34,h2,h8
b $7E08
@ $7E08 label=spr_020
B $7E08,226,h2,h8
b $7EEA
@ $7EEA label=spr_021
B $7EEA,70,h2,h8*8,h4
b $7F30
@ $7F30 label=spr_022
B $7F30,128,h2,h8*15,h6
b $7FB0
@ $7FB0 label=spr_023
B $7FB0,242,h2,h8
b $80A2
@ $80A2 label=spr_024
B $80A2,194,h2,h8
b $8164
@ $8164 label=spr_025
B $8164,122,h2,h8
b $81DE
@ $81DE label=spr_026
B $81DE,128,h2,h8*15,h6
b $825E
@ $825E label=spr_027
B $825E,140,h2,h8*17,h2
b $82EA
@ $82EA label=spr_028
B $82EA,146,h2,h8
b $837C
@ $837C label=spr_029
B $837C,146,h2,h8
b $840E
@ $840E label=spr_030
B $840E,146,h2,h8
b $84A0
@ $84A0 label=spr_031
B $84A0,116,h2,h8*14,h2
b $8514
@ $8514 label=spr_032
B $8514,134,h2,h8*16,h4
b $859A
@ $859A label=spr_033
B $859A,140,h2,h8*17,h2
b $8626
@ $8626 label=spr_034
B $8626,110,h2,h8*13,h4
b $8694
@ $8694 label=spr_035
B $8694,146,h2,h8
b $8726
@ $8726 label=spr_036
B $8726,128,h2,h8*15,h6
b $87A6
@ $87A6 label=spr_037
B $87A6,66,h2,h8
b $87E8
@ $87E8 label=spr_038
B $87E8,66,h2,h8
b $882A
@ $882A label=spr_039
B $882A,122,h2,h8
b $88A4
@ $88A4 label=spr_040
B $88A4,116,h2,h8*14,h2
b $8918
@ $8918 label=spr_041
B $8918,122,h2,h8
b $8992
@ $8992 label=spr_042
B $8992,122,h2,h8
b $8A0C
@ $8A0C label=spr_043
B $8A0C,254,h2,h8*31,h4
b $8B0A
@ $8B0A label=spr_044
B $8B0A,234,h2,h8
b $8BF4
@ $8BF4 label=spr_045
B $8BF4,250,h2,h8
b $8CEE
@ $8CEE label=spr_046
B $8CEE,146,h2,h8
b $8D80
@ $8D80 label=spr_047
B $8D80,152,h2,h8*18,h6
b $8E18
@ $8E18 label=spr_048
B $8E18,152,h2,h8*18,h6
b $8EB0
@ $8EB0 label=spr_049
B $8EB0,146,h2,h8
b $8F42
@ $8F42 label=spr_050
B $8F42,146,h2,h8
b $8FD4
@ $8FD4 label=spr_051
B $8FD4,146,h2,h8
b $9066
@ $9066 label=spr_052
B $9066,152,h2,h8*18,h6
b $90FE
@ $90FE label=spr_053
B $90FE,152,h2,h8*18,h6
b $9196
@ $9196 label=spr_054
B $9196,152,h2,h8*18,h6
b $922E
@ $922E label=spr_055
B $922E,98,h2,h8
b $9290
@ $9290 label=spr_056
B $9290,98,h2,h8
b $92F2
@ $92F2 label=spr_057
B $92F2,98,h2,h8
b $9354
@ $9354 label=spr_058
B $9354,98,h2,h8
b $93B6
@ $93B6 label=spr_059
B $93B6,98,h2,h8
b $9418
@ $9418 label=spr_060
B $9418,98,h2,h8
b $947A
@ $947A label=spr_061
B $947A,98,h2,h8
b $94DC
@ $94DC label=spr_062
B $94DC,98,h2,h8
b $953E
@ $953E label=spr_063
B $953E,146,h2,h8
b $95D0
@ $95D0 label=spr_064
B $95D0,152,h2,h8*18,h6
b $9668
@ $9668 label=spr_065
B $9668,152,h2,h8*18,h6
b $9700
@ $9700 label=spr_066
B $9700,194,h2,h8
b $97C2
@ $97C2 label=spr_067
B $97C2,194,h2,h8
b $9884
@ $9884 label=spr_068
B $9884,194,h2,h8
b $9946
@ $9946 label=spr_069
B $9946,194,h2,h8
b $9A08
@ $9A08 label=spr_070
B $9A08,194,h2,h8
b $9ACA
@ $9ACA label=spr_071
B $9ACA,314,h2,h8
b $9C04
@ $9C04 label=spr_072
B $9C04,142,h2,h8*17,h4
b $9C92
@ $9C92 label=spr_073
B $9C92,194,h2,h8
b $9D54
@ $9D54 label=spr_074
B $9D54,266,h2,h8
b $9E5E
@ $9E5E label=spr_075
B $9E5E,90,h2,h8
b $9EB8
@ $9EB8 label=spr_076
B $9EB8,252,h2,h8*31,h2
b $9FB4
@ $9FB4 label=spr_077
B $9FB4,146,h2,h8
b $A046
@ $A046 label=spr_078
B $A046,110,h2,h8*13,h4
b $A0B4
@ $A0B4 label=spr_079
B $A0B4,98,h2,h8
b $A116
@ $A116 label=spr_080
B $A116,98,h2,h8
b $A178
@ $A178 label=spr_081
B $A178,98,h2,h8
b $A1DA
@ $A1DA label=spr_082
B $A1DA,98,h2,h8
b $A23C
@ $A23C label=spr_083
B $A23C,98,h2,h8
b $A29E
@ $A29E label=spr_084
B $A29E,98,h2,h8
b $A300
@ $A300 label=spr_085
B $A300,98,h2,h8
b $A362
@ $A362 label=spr_086
B $A362,98,h2,h8
b $A3C4
@ $A3C4 label=spr_087
B $A3C4,176,h2,h8*21,h6
b $A474
@ $A474 label=spr_088
B $A474,176,h2,h8*21,h6
b $A524
@ $A524 label=spr_089
B $A524,176,h2,h8*21,h6
b $A5D4
@ $A5D4 label=spr_090
B $A5D4,176,h2,h8*21,h6
b $A684
@ $A684 label=spr_091
B $A684,182,h2,h8*22,h4
b $A73A
@ $A73A label=spr_092
B $A73A,182,h2,h8*22,h4
b $A7F0
@ $A7F0 label=spr_093
B $A7F0,182,h2,h8*22,h4
b $A8A6
@ $A8A6 label=spr_094
B $A8A6,182,h2,h8*22,h4
b $A95C
@ $A95C label=spr_095
B $A95C,176,h2,h8*21,h6
b $AA0C
@ $AA0C label=spr_096
B $AA0C,176,h2,h8*21,h6
b $AABC
@ $AABC label=spr_097
B $AABC,182,h2,h8*22,h4
b $AB72
@ $AB72 label=spr_098
B $AB72,182,h2,h8*22,h4
b $AC28
@ $AC28 label=spr_099
B $AC28,194,h2,h8
b $ACEA
@ $ACEA label=spr_100
B $ACEA,200,h2,h8*24,h6
b $ADB2
@ $ADB2 label=spr_101
B $ADB2,230,h2,h8*28,h4
b $AE98
@ $AE98 label=spr_102
B $AE98,212,h2,h8*26,h2
c $AF6C
@ $AF6C label=START
C $AF6C,h3
C $AF6F,h3
C $AF72,h3
C $AF76,9,h3,1,h5
c $AF7F
@ $AF7F label=start_menu
C $AF7F,h3
C $AF82,h3
C $AF85,h3
c $AF88
@ $AF88 label=main
C $AF88,7,h3,1,h3
C $AF8F,h3
C $AF92,h2
C $AF94,h9
C $AF9F,h9
C $AFA8,h3
C $AFAB,h3
C $AFAE,h6
C $AFB4,h3
c $AFB7
@ $AFB7 label=player_dies
C $AFB7,h3
c $AFBA
@ $AFBA label=game_loop
C $AFBA,h3
c $AFBD
@ $AFBD label=onscreen_loop
C $AFBD,h6
C $AFC3,h4
c $AFC7
@ $AFC7 label=update_sprite_loop
C $AFC7,10,h6,1,h3
C $AFD2,h3
c $AFD5
@ $AFD5 label=jump_to_upd_object
C $AFD5,h6
c $AFDB
@ $AFDB label=jump_to_tbl_entry
C $AFDB,h2
c $AFE4
@ $AFE4 label=ret_from_tbl_jp
C $AFE7,h3
C $AFEB,h6
C $AFF6,h3
C $AFFC,h2
C $AFFE,h2
c $B000
@ $B000 label=loc_B000
C $B000,19,h3,1,h6,3,h6
C $B015,h6
C $B01B,h3
C $B01E,h6
C $B025,h6
C $B02D,h2
C $B030,h5
c $B035
@ $B035 label=game_delay
C $B035,h3
c $B038
@ $B038 label=delay_loop
C $B03B,h4
c $B03F
@ $B03F label=no_delay
C $B03F,h3
C $B043,h2
C $B046,h3
C $B049,h3
C $B04C,h3
C $B04F,h31
C $B06E,h6
c $B074
@ $B074 label=loc_B074
C $B075,h7
C $B07C,h3
C $B07F,h3
C $B082,h6
c $B088
@ $B088 label=reset_objs_wipe_flag
C $B088,h2
C $B08A,h3
C $B08D,h3
c $B090
@ $B090 label=loc_B090
C $B093,h2
b $B096
@ $B096 label=upd_sprite_jmp_tbl
W $B096,2,h2
W $B098,2,h2
W $B09A,2,h2
W $B09C,2,h2
W $B09E,2,h2
W $B0A0,2,h2
W $B0A2,2,h2
W $B0A4,2,h2
W $B0A6,2,h2
W $B0A8,2,h2
W $B0AA,2,h2
W $B0AC,2,h2
W $B0AE,2,h2
W $B0B0,6,h2
W $B0B6,2,h2
W $B0B8,10,h2
W $B0C2,2,h2
W $B0C4,2,h2
W $B0C6,12,h2
W $B0D2,2,h2
W $B0D4,2,h2
W $B0D6,2,h2
W $B0D8,30,h2
W $B0F6,2,h2
W $B0F8,10,h2
W $B102,2,h2
W $B104,2,h2
W $B106,12,h2
W $B112,2,h2
W $B114,2,h2
W $B116,2,h2
W $B118,30,h2
W $B136,2,h2
W $B138,6,h2
W $B13E,2,h2
W $B140,2,h2
W $B142,2,h2
W $B144,2,h2
W $B146,2,h2
W $B148,2,h2
W $B14A,2,h2
W $B14C,2,h2
W $B14E,2,h2
W $B150,6,h2
W $B156,2,h2
W $B158,2,h2
W $B15A,2,h2
W $B15C,2,h2
W $B15E,2,h2
W $B160,2,h2
W $B162,2,h2
W $B164,2,h2
W $B166,2,h2
W $B168,2,h2
W $B16A,2,h2
W $B16C,2,h2
W $B16E,2,h2
W $B170,2,h2
W $B172,2,h2
W $B174,2,h2
W $B176,2,h2
W $B178,12,h2
W $B184,2,h2
W $B186,2,h2
W $B188,12,h2
W $B194,2,h2
W $B196,2,h2
W $B198,4,h2
W $B19C,2,h2
W $B19E,18,h2
W $B1B0,2,h2
W $B1B2,2,h2
W $B1B4,2,h2
W $B1B6,2,h2
W $B1B8,10,h2
W $B1C2,2,h2
W $B1C4,14,h2
W $B1D2,2,h2
W $B1D4,2,h2
W $B1D6,2,h2
W $B1D8,6,h2
W $B1DE,2,h2
W $B1E0,6,h2
W $B1E6,2,h2
W $B1E8,2,h2
W $B1EA,2,h2
W $B1EC,2,h2
W $B1EE,2,h2
W $B1F0,2,h2
W $B1F2,2,h2
W $B1F4,2,h2
W $B1F6,2,h2
W $B1F8,2,h2
W $B1FA,2,h2
W $B1FC,2,h2
W $B1FE,2,h2
W $B200,2,h2
W $B202,2,h2
W $B204,2,h2
W $B206,2,h2
W $B208,2,h2
W $B20A,2,h2
W $B20C,2,h2
b $B20E
@ $B20E label=start_game_tune
B $B20E,10,h8,h2
b $B218
@ $B218 label=game_over_tune
B $B218,33,h8*4,h1
b $B239
@ $B239 label=game_complete_tune
B $B239,26,h8*3,h2
b $B253
@ $B253 label=menu_tune
B $B253,99,h8*12,h3
c $B2B6
@ $B2B6 label=play_audio_wait_key
C $B2B6,h3
c $B2BE
@ $B2BE label=play_audio_until_keypress
C $B2BF,h5
c $B2C5
@ $B2C5 label=loc_B2C5
C $B2C6,h2
C $B2C8,h7
c $B2CF
@ $B2CF label=play_audio
C $B2D0,h2
C $B2D2,h7
c $B2D9
@ $B2D9 label=end_audio
c $B2DA
@ $B2DA label=play_note
C $B2DA,h2
C $B2DC,5,h2,1,h2
C $B2E2,h3
C $B2E5,h3
C $B2EE,h2
C $B2F3,h2
c $B2F9
@ $B2F9 label=calc_duration
C $B2FA,h2
C $B2FD,h2
c $B2FF
@ $B2FF label=loc_B2FF
c $B300
@ $B300 label=loc_B300
C $B302,h2
c $B304
@ $B304 label=loc_B304
C $B304,11,h2,1,h2,2,h4
c $B30F
@ $B30F label=loc_B30F
C $B30F,11,h2,1,h2,4,h2
c $B31C
@ $B31C label=snd_delay
C $B320,7,h2,2,h3
c $B327
@ $B327 label=loc_B327
c $B328
@ $B328 label=loc_B328
C $B32B,6,h2,2,h2
b $B332
@ $B332 label=freq_tbl
B $B332,183,h3
c $B3E9
@ $B3E9 label=audio_B3E9
C $B3E9,8,h5,1,h2
C $B3F1,h3
C $B3F6,h5
b $B3FB
@ $B3FB label=byte_B3FB
B $B3FB,8,h8
c $B403
@ $B403 label=audio_B403
C $B403,h3
C $B407,h2
C $B40A,h3
c $B40D
@ $B40D label=loc_B40D
C $B410,8,h5,1,h2
c $B419
@ $B419 label=audio_B419
C $B419,h3
C $B41E,h4
c $B423
@ $B423 label=loc_B423
C $B427,6,h3,1,h2
c $B42E
@ $B42E label=audio_B42E
C $B42E,h5
c $B433
@ $B433 label=loc_B433
C $B433,13,h2,2,h2,1,h3,1,h2
c $B441
@ $B441 label=audio_B441
C $B441,h2
c $B443
@ $B443 label=loc_B443
C $B44A,6,h3,1,h2
c $B451
@ $B451 label=audio_B451
C $B451,h3
c $B454
@ $B454 label=audio_B454
C $B458,h5
c $B45D
@ $B45D label=audio_B45D
C $B45D,h3
C $B460,h2
c $B462
@ $B462 label=audio_B462
C $B462,h3
C $B465,h2
c $B467
@ $B467 label=audio_B467
C $B467,h11
c $B472
@ $B472 label=audio_B472
C $B472,10,h3,3,h4
c $B47D
@ $B47D label=loc_B47D
C $B47E,h2
C $B482,6,h3,1,h2
c $B489
@ $B489 label=audio_B489
C $B489,12,h3,1,h5,1,h2
c $B495
@ $B495 label=loc_B495
C $B497,11,h2,1,h5,1,h2
c $B4A3
@ $B4A3 label=toggle_audio_hw_x16
C $B4A3,h5
c $B4A8
@ $B4A8 label=toggle_audio_hw_x24
C $B4A8,h5
c $B4AD
@ $B4AD label=audio_guard_wizard
C $B4AD,h3
C $B4B0,h2
C $B4B3,8,h5,1,h2
c $B4BB
@ $B4BB label=audio_B4BB
C $B4BB,h5
c $B4C1
@ $B4C1 label=audio_B4C1
C $B4C1,h5
c $B4C6
@ $B4C6 label=loc_B4C6
C $B4C8,h2
C $B4CA,h3
c $B4D1
@ $B4D1 label=loc_B4D1
C $B4D1,h3
C $B4D7,h3
C $B4E3,h2
c $B4E6
@ $B4E6 label=toggle_audio_hw_xC
C $B4E6,6,h3,1,h2
c $B4ED
@ $B4ED label=toggle_audio_hw
C $B4ED,h2
C $B4EF,h2
c $B4F2
@ $B4F2 label=loc_B4F2
C $B4F2,h2
C $B4F6,h2
c $B4F9
@ $B4F9 label=loc_B4F9
C $B4F9,h2
c $B4FD
@ $B4FD label=do_any_objs_intersect
C $B502,h4
C $B506,h2
C $B508,h2
C $B50C,h4
c $B510
@ $B510 label=loc_B510
C $B510,h3
C $B513,h5
C $B518,h5
C $B51D,h5
C $B522,h2
c $B524
@ $B524 label=loc_B524
C $B529,h4
c $B52E
@ $B52E label=loc_B52E
C $B52E,h3
C $B533,5,h2,1,h2
c $B538
@ $B538 label=is_object_not_ignored
C $B538,h3
C $B53D,h3
C $B541,h2
c $B544
@ $B544 label=shuffle_objects_required
C $B544,h7
c $B54C
@ $B54C label=loc_B54C
C $B54C,h9
c $B555
@ $B555 label=loc_B555
C $B555,16,h6,2,h5,1,h2
c $B566
@ $B566 label=upd_131_to_133
C $B566,h3
C $B569,h3
C $B56C,h2
C $B56E,h2
C $B570,hh4
C $B574,h3
C $B578,h2
C $B57B,h3
C $B57E,h2
C $B582,h2
C $B585,h6
b $B58B
@ $B58B label=dX_dY_tbl
W $B58B,2,h2
W $B58D,2,h2
W $B58F,2,h2
W $B591,2,h2
c $B593
@ $B593 label=p4_m4
C $B593,h3
c $B596
@ $B596 label=save_dX_dY
C $B596,h3
C $B599,h3
C $B59C,h3
C $B59F,h2
C $B5A1,h2
c $B5A4
@ $B5A4 label=loc_B5A4
C $B5A4,h2
C $B5A6,h3
c $B5A9
@ $B5A9 label=loc_B5A9
C $B5A9,h6
c $B5AF
@ $B5AF label=dec_dZ_wipe_and_draw
C $B5AF,h6
c $B5B5
@ $B5B5 label=p4_p4
C $B5B5,h5
c $B5BA
@ $B5BA label=m4_m4
C $B5BA,h5
c $B5BF
@ $B5BF label=m4_p4
C $B5BF,h5
c $B5C4
@ $B5C4 label=loc_B5C4
C $B5C4,h3
C $B5C7,h3
C $B5CA,h3
c $B5CF
@ $B5CF label=loc_B5CF
C $B5CF,h2
C $B5D1,h2
C $B5D3,h3
C $B5D6,h3
C $B5D9,h3
c $B5DE
@ $B5DE label=loc_B5DE
C $B5DE,h2
C $B5E0,h3
c $B5E3
@ $B5E3 label=loc_B5E3
C $B5E3,h4
C $B5E7,h4
C $B5EB,hh4
C $B5EF,h3
C $B5F2,h5
c $B5F7
@ $B5F7 label=read_port
C $B5F7,h2
C $B5F9,h2
C $B5FC,h2
c $B5FF
@ $B5FF label=upd_182_183
C $B5FF,h3
C $B602,h3
C $B605,h3
C $B609,h3
C $B60C,h6
C $B613,h3
C $B616,h3
C $B619,h5
C $B61E,h2
C $B620,h2
C $B622,h2
C $B624,h2
c $B626
@ $B626 label=loc_B626
C $B626,h3
C $B629,h3
C $B62C,15,h9,1,h5
c $B63C
@ $B63C label=loc_B63C
C $B63C,h4
C $B640,h2
C $B642,h3
C $B645,h3
C $B649,h6
c $B64F
@ $B64F label=loc_B64F
C $B651,h4
C $B655,h3
C $B658,h3
C $B65B,h2
c $B65D
@ $B65D label=loc_B65D
C $B65D,h2
c $B661
@ $B661 label=loc_B661
C $B661,h3
C $B664,hh4
c $B668
@ $B668 label=loc_B668
C $B668,h6
c $B66E
@ $B66E label=loc_B66E
C $B66E,h3
C $B671,h3
C $B674,h2
c $B676
@ $B676 label=loc_B676
C $B676,h2
c $B67A
@ $B67A label=loc_B67A
C $B67A,h3
C $B67D,hh4
C $B681,h2
c $B683
@ $B683 label=upd_91
C $B683,h3
C $B686,h4
C $B68B,h4
C $B68F,hh4
C $B693,h3
C $B696,h4
C $B69A,h5
c $B69F
@ $B69F label=loc_B69F
C $B69F,h3
c $B6A2
@ $B6A2 label=upd_143
C $B6A2,h3
C $B6A5,h4
C $B6AA,hh4
C $B6AE,h3
c $B6B1
@ $B6B1 label=upd_55
C $B6B1,h3
C $B6B4,h3
C $B6B7,h2
c $B6B9
@ $B6B9 label=upd_54
C $B6B9,h3
C $B6BC,h3
c $B6BF
@ $B6BF label=loc_B6BF
C $B6C0,h3
C $B6C4,h3
C $B6C7,19,h3,5,h2,1,h3,3,h2
c $B6DB
@ $B6DB label=loc_B6DB
C $B6DB,h2
c $B6DE
@ $B6DE label=loc_B6DE
C $B6DE,15,h7,1,h7
c $B6EF
@ $B6EF label=loc_B6EF
C $B6EF,h3
C $B6F2,hh4
C $B6F6,h3
c $B6F9
@ $B6F9 label=upd_144_to_149_152_to_157
C $B6F9,h3
C $B6FC,h3
C $B6FF,h3
C $B703,h3
C $B706,h3
C $B709,h3
C $B70C,h2
C $B710,h2
C $B712,h4
c $B716
@ $B716 label=loc_B716
C $B716,h4
c $B71A
@ $B71A label=loc_B71A
C $B71A,h6
c $B720
@ $B720 label=loc_B720
C $B720,h6
c $B726
@ $B726 label=loc_B726
C $B726,h4
C $B72A,h2
C $B72C,h4
c $B730
@ $B730 label=loc_B730
C $B730,h6
c $B736
@ $B736 label=loc_B736
C $B736,h6
c $B73C
@ $B73C label=upd_150_151
C $B73C,h3
C $B73F,h4
C $B743,h2
C $B745,h2
c $B749
@ $B749 label=loc_B749
C $B749,h3
C $B74C,h3
C $B74F,h6
C $B755,h4
C $B759,h5
C $B75E,h2
C $B760,h3
c $B763
@ $B763 label=loc_B763
C $B763,h3
C $B766,h3
C $B769,h3
c $B76C
@ $B76C label=set_guard_wizard_sprite
C $B76C,h3
C $B76F,h3
C $B773,h3
C $B776,h3
C $B779,h2
C $B77D,h2
C $B77F,h4
c $B783
@ $B783 label=loc_B783
C $B783,h4
c $B788
@ $B788 label=loc_B788
C $B788,h6
c $B78E
@ $B78E label=loc_B78E
C $B78E,h4
C $B792,h2
C $B794,h4
c $B798
@ $B798 label=loc_B798
C $B798,h4
c $B79D
@ $B79D label=loc_B79D
C $B79D,h6
c $B7A3
@ $B7A3 label=upd_22
C $B7A3,h3
C $B7A6,h3
c $B7A9
@ $B7A9 label=upd_63
C $B7A9,h9
C $B7B4,h4
C $B7B8,h5
C $B7C0,h3
C $B7C3,h2
C $B7C6,h4
C $B7CA,h2
c $B7CD
@ $B7CD label=spiked_ball_drop
C $B7CD,h3
C $B7D0,h4
C $B7D4,h5
c $B7D9
@ $B7D9 label=draw_spiked_ball
C $B7D9,h3
c $B7DC
@ $B7DC label=loc_B7DC
C $B7DC,h7
C $B7E3,h2
C $B7E5,h2
c $B7E7
@ $B7E7 label=upd_23
C $B7E7,h6
c $B7ED
@ $B7ED label=upd_86_87
C $B7ED,h3
C $B7F0,hh4
C $B7F4,h4
C $B7F8,h2
C $B7FA,h2
c $B7FE
@ $B7FE label=loc_B7FE
C $B7FE,h9
C $B807,h4
C $B80B,h4
c $B80F
@ $B80F label=upd_180_181
C $B80F,h3
C $B812,hh4
C $B816,h4
C $B81A,h2
C $B81C,h2
c $B820
@ $B820 label=loc_B820
C $B820,h9
C $B829,h4
C $B82D,h2
c $B82F
@ $B82F label=loc_B82F
C $B82F,h2
C $B831,h3
C $B834,h6
c $B83A
@ $B83A label=loc_B83A
C $B83A,h5
c $B83F
@ $B83F label=upd_176_177
C $B83F,12,h8,1,h3
C $B84B,h2
C $B84D,h3
C $B850,h6
c $B856
@ $B856 label=set_deadly_wipe_and_draw_flags
C $B856,h6
c $B85C
@ $B85C label=set_both_deadly_flags
C $B85C,h3
C $B85F,h2
C $B861,h3
c $B865
@ $B865 label=upd_178_179
C $B865,h6
C $B86C,h2
C $B86E,h3
C $B871,h2
C $B873,h3
c $B876
@ $B876 label=loc_B876
C $B876,h6
C $B87C,h4
C $B880,h5
C $B885,h4
C $B889,h2
C $B88B,h4
C $B88F,h3
c $B892
@ $B892 label=loc_B892
C $B892,h2
c $B894
@ $B894 label=ball_up
C $B894,10,hh4,h6
C $B89E,h3
C $B8A1,h2
C $B8A3,h4
C $B8A7,h2
c $B8A9
@ $B8A9 label=init_cauldron_bubbles
C $B8A9,h3
C $B8AC,h2
C $B8AF,h3
C $B8B5,h3
C $B8BA,h3
C $B8BD,h3
C $B8C5,h3
b $B8C8
@ $B8C8 label=cauldron_bubbles
B $B8C8,18,h8*2,h2
c $B8DA
@ $B8DA label=upd_160_to_163
C $B8DA,h6
C $B8E1,h3
C $B8E4,h4
C $B8E8,h6
C $B8EE,h3
C $B8F1,h2
C $B8F3,hh4
C $B8F7,h2
C $B8F9,hh4
C $B8FD,h3
C $B900,h2
C $B902,h2
C $B904,h2
C $B906,h3
C $B909,10,h7,1,h2
C $B913,h3
c $B916
@ $B916 label=loc_B916
C $B916,h3
c $B919
@ $B919 label=loc_B919
C $B919,h4
C $B91D,h4
C $B921,h2
c $B923
@ $B923 label=upd_168_to_175
C $B923,h3
C $B926,hh4
C $B92A,h2
c $B92C
@ $B92C label=upd_164_to_167
C $B92C,h3
C $B92F,h3
C $B932,h2
C $B934,h5
C $B93B,h2
C $B93D,h3
C $B940,h2
c $B942
@ $B942 label=loc_B942
C $B942,h3
c $B945
@ $B945 label=loc_B945
C $B945,h9
C $B94E,h3
C $B951,h2
C $B953,h2
C $B955,h5
C $B95A,h2
C $B95C,h2
c $B95E
@ $B95E label=upd_111
C $B95E,hh4
c $B962
@ $B962 label=loc_B962
C $B962,h3
c $B965
@ $B965 label=move_towards_plyr
C $B965,h3
C $B968,h3
C $B96E,h3
c $B973
@ $B973 label=loc_B973
C $B973,h3
C $B976,h3
C $B97C,h3
c $B981
@ $B981 label=loc_B981
C $B981,h3
c $B985
@ $B985 label=toggle_next_prev_sprite
C $B985,h3
C $B988,h2
C $B98A,h2
c $B98C
@ $B98C label=next_graphic_no_mod_4
C $B98C,h3
C $B990,h2
C $B995,h2
c $B998
@ $B998 label=save_graphic_no
C $B998,h3
c $B99C
@ $B99C label=upd_141
C $B99C,h3
c $B99F
@ $B99F label=upd_142
C $B99F,h6
c $B9A5
@ $B9A5 label=upd_30_31_158_159
C $B9A5,h9
C $B9AE,h3
C $B9B1,h3
C $B9B4,h3
C $B9B7,h3
C $B9BA,h3
C $B9BD,h3
C $B9C0,h3
C $B9C3,h3
C $B9C6,h6
c $B9CC
@ $B9CC label=move_guard_wizard_NSEW
C $B9CC,h6
C $B9D2,h2
C $B9D5,h3
b $B9D8
@ $B9D8 label=guard_NSEW_tbl
W $B9D8,8,h2
c $B9E0
@ $B9E0 label=guard_W
C $B9E0,h3
C $B9E3,h4
C $B9E8,h3
c $B9EB
@ $B9EB label=next_guard_dir
C $B9EB,h3
C $B9F0,h2
C $B9F4,h2
C $B9F7,h3
c $B9FB
@ $B9FB label=guard_N
C $B9FB,h3
C $B9FE,h4
C $BA03,h3
C $BA06,h2
c $BA08
@ $BA08 label=guard_E
C $BA08,h3
C $BA0B,h4
C $BA10,h3
C $BA13,h2
c $BA15
@ $BA15 label=guard_S
C $BA15,h3
C $BA18,h4
C $BA1D,h3
C $BA20,h2
c $BA22
@ $BA22 label=game_over
C $BA22,7,h3,1,h3
c $BA29
@ $BA29 label=loc_BA29
C $BA29,h6
C $BA2F,h3
C $BA33,h11
C $BA3E,h6
C $BA44,h2
C $BA46,30,h9,1,h2,1,h5,4,h2,1,h5
C $BA68,h9
C $BA72,h2
C $BA74,h2
C $BA76,h2
c $BA79
@ $BA79 label=loc_BA79
C $BA79,h3
C $BA7C,h2
C $BA7E,h9
c $BA87
@ $BA87 label=loc_BA87
C $BA88,h3
C $BA8B,h8
C $BA93,h2
C $BA95,h3
C $BA98,h3
c $BA9B
@ $BA9B label=wait_for_key_press
C $BA9B,h3
c $BA9E
@ $BA9E label=loc_BA9E
C $BA9F,h3
C $BAA6,h4
c $BAAB
@ $BAAB label=game_complete_msg
C $BAAB,39,h9,1,h8,1,h20
b $BAD2
@ $BAD2 label=complete_colours
B $BAD2,6,h6
b $BAD8
@ $BAD8 label=complete_xy
B $BAD8,12,h2
b $BAE4
@ $BAE4 label=the_potion_casts
B $BAE4,16,h8
B $BAF4,16,h8
B $BB04,20,h8*2,h4
B $BB18,20,h8*2,h4
B $BB2C,12,h8,h4
B $BB38,20,h8*2,h4
b $BB4C
@ $BB4C label=gameover_colours
B $BB4C,6,h6
b $BB52
@ $BB52 label=gameover_xy
B $BB52,12,h8,h4
b $BB5E
@ $BB5E label=a_GAME_OVER
B $BB5E,10,h8,h2
B $BB68,12,h8,h4
B $BB74,19,h8*2,h3
B $BB87,15,h8,h7
B $BB96,19,h8*2,h3
B $BBA9,14,h8,h6
b $BBB7
@ $BBB7 label=rating_tbl
B $BBB7,16,h8
b $BBC7
@ $BBC7 label=a_POOR
B $BBC7,8,h8
b $BBCF
@ $BBCF label=a_AVERAGE
B $BBCF,9,h8,h1
b $BBD8
@ $BBD8 label=a_FAIR
B $BBD8,8,h8
b $BBE0
@ $BBE0 label=a_GOOD
B $BBE0,8,h8
b $BBE8
@ $BBE8 label=a_EXCELLENT
B $BBE8,10,h8,h2
b $BBF2
@ $BBF2 label=a_MARVELLOUS
B $BBF2,11,h8,h3
b $BBFD
@ $BBFD label=a_HERO
B $BBFD,8,h8
b $BC05
@ $BC05 label=a_ADVENTURER
B $BC05,11,h8,h3
c $BC10
@ $BC10 label=calc_and_display_percent
C $BC10,h2
C $BC12,h3
C $BC15,h3
c $BC18
@ $BC18 label=count_screens
c $BC1B
@ $BC1B label=loc_BC1B
C $BC1C,h2
c $BC1F
@ $BC1F label=loc_BC1F
C $BC1F,h2
C $BC23,h2
C $BC27,h6
C $BC31,h3
C $BC34,h3
c $BC38
@ $BC38 label=loc_BC38
C $BC39,h2
C $BC3D,h2
C $BC3F,h3
C $BC43,h2
C $BC46,h7
C $BC4E,h9
C $BC57,h2
C $BC5B,h2
C $BC5E,h3
c $BC61
@ $BC61 label=loc_BC61
C $BC63,h3
c $BC66
@ $BC66 label=print_days
C $BC66,h11
C $BC71,8,h5,1,h2
c $BC7A
@ $BC7A label=print_lives_gfx
C $BC7A,h4
C $BC7E,hh4
C $BC82,hh4
C $BC86,hh4
C $BC8A,hh4
C $BC8E,h21
c $BCA3
@ $BCA3 label=print_lives
C $BCA3,h3
C $BCA6,h2
C $BCA8,h6
c $BCAE
@ $BCAE label=print_BCD_number
C $BCAF,h6
c $BCB6
@ $BCB6 label=loc_BCB6
C $BCBB,h2
C $BCBD,h3
c $BCC0
@ $BCC0 label=print_BCD_lsd
C $BCC1,h2
C $BCC3,h3
C $BCC7,h2
c $BCCA
@ $BCCA label=display_day
C $BCCA,8,h3,1,h4
C $BCD2,h2
C $BCD4,h6
C $BCDA,h6
C $BCE0,h3
C $BCE4,h3
b $BCE7
@ $BCE7 label=day_txt
B $BCE7,5,h5
b $BCEC
@ $BCEC label=day_font
B $BCEC,32,h8
c $BD0C
@ $BD0C label=do_menu_selection
C $BD0D,h6
C $BD13,h2
c $BD15
@ $BD15 label=loc_BD15
C $BD18,h11
c $BD23
@ $BD23 label=menu_loop
C $BD23,h9
C $BD2C,h2
C $BD2E,h3
C $BD32,h6
C $BD3A,h2
C $BD3C,h2
c $BD3E
@ $BD3E label=check_for_kempston_joystick
C $BD40,h2
C $BD42,h2
C $BD44,h2
c $BD46
@ $BD46 label=check_for_cursor_joystick
C $BD48,h2
C $BD4A,h2
C $BD4C,h2
c $BD4E
@ $BD4E label=check_for_interface_ii
C $BD50,h2
C $BD52,h2
c $BD54
@ $BD54 label=check_for_directional_control
C $BD54,h6
C $BD5C,h2
C $BD60,h2
C $BD64,h3
C $BD67,h2
C $BD69,h3
c $BD6C
@ $BD6C label=check_for_start_game
C $BD6C,h3
C $BD70,h3
C $BD73,h2
C $BD75,h3
C $BD7B,h3
C $BD7F,h6
c $BD85
@ $BD85 label=clr_debounce
C $BD87,h2
c $BD89
@ $BD89 label=flash_menu
C $BD89,h6
C $BD90,h2
C $BD92,10,h5,2,h3
C $BD9C,h2
b $BDA2
@ $BDA2 label=menu_colours
B $BDA2,8,h8
b $BDAA
@ $BDAA label=menu_xy
B $BDAA,16,h2
b $BDBA
@ $BDBA label=menu_text
B $BDBA,11,h8,h3
B $BDC5,10,h8,h2
B $BDCF,19,h8*2,h3
B $BDE2,19,h8*2,h3
B $BDF5,14,h8,h6
B $BE03,21,h8*2,h5
B $BE18,12,h8,h4
B $BE24,13,h8,h5
c $BE31
@ $BE31 label=print_text_single_colour
C $BE32,h6
C $BE3A,h3
C $BE3F,6,h3,1,h2
c $BE45
@ $BE45 label=print_text_std_font
C $BE46,h6
c $BE4C
@ $BE4C label=print_text
C $BE4E,h3
c $BE56
@ $BE56 label=loc_BE56
C $BE59,h3
c $BE5F
@ $BE5F label=loc_BE5F
C $BE63,h2
C $BE66,h3
C $BE70,h2
c $BE72
@ $BE72 label=loc_BE72
C $BE72,h2
C $BE75,h3
c $BE7F
@ $BE7F label=print_8x8
C $BE83,h2
C $BE88,h4
C $BE8F,h2
c $BE91
@ $BE91 label=loc_BE91
C $BE95,h3
C $BE9A,6,h2,1,h3
c $BEA3
@ $BEA3 label=toggle_selected
C $BEA4,h2
c $BEA6
@ $BEA6 label=loc_BEA6
C $BEA8,h2
c $BEAA
@ $BEAA label=loc_BEAA
C $BEAB,h2
c $BEAD
@ $BEAD label=loc_BEAD
c $BEAF
@ $BEAF label=loc_BEAF
C $BEB0,h2
c $BEB3
@ $BEB3 label=display_menu
C $BEB3,h3
C $BEB7,h6
C $BEBD,h2
c $BEBF
@ $BEBF label=display_text_list
C $BEC1,h3
C $BECE,h3
C $BED3,h5
C $BEDB,h9
c $BEE4
@ $BEE4 label=multiple_print_sprite
C $BEE7,h3
C $BEED,h3
C $BEF1,h3
C $BEF4,h3
C $BEF8,h3
C $BEFB,h2
c $BEFE
@ $BEFE label=upd_120_to_126
C $BEFE,9,h6,1,h2
C $BF08,h3
C $BF0B,h6
c $BF11
@ $BF11 label=upd_127
C $BF11,h7
C $BF18,h3
C $BF1B,h3
C $BF1E,h3
c $BF21
@ $BF21 label=init_death_sparkles
C $BF21,hh4
C $BF25,h4
C $BF29,h2
c $BF2B
@ $BF2B label=upd_112_to_118_184
C $BF2B,h3
C $BF2E,h3
c $BF31
@ $BF31 label=loc_BF31
C $BF31,h6
c $BF37
@ $BF37 label=upd_185_187
C $BF37,h6
C $BF3D,h2
c $BF3F
@ $BF3F label=upd_119
C $BF3F,h6
c $BF45
@ $BF45 label=display_objects_carried
C $BF45,h3
C $BF4B,h3
c $BF4E
@ $BF4E label=display_objects
C $BF50,h4
C $BF54,h2
C $BF56,h3
c $BF59
@ $BF59 label=display_object
C $BF5E,h2
C $BF6A,h2
C $BF6C,h3
C $BF6F,hh4
C $BF73,h3
C $BF76,h3
C $BF7A,h3
C $BF7F,h3
C $BF83,h3
C $BF89,h2
C $BF8B,h3
C $BF8E,h3
c $BF91
@ $BF91 label=loc_BF91
C $BF91,h3
C $BF94,h3
C $BF97,h6
C $BF9F,h3
C $BFA2,h3
C $BFAA,8,h2,1,h5
C $BFB4,h3
C $BFB7,h3
C $BFBA,6,h2,1,h3
C $BFC2,h3
C $BFC5,h3
C $BFCE,h2
b $BFD3
@ $BFD3 label=object_attributes
B $BFD3,8,h8
b $BFDB
@ $BFDB label=sprite_scratchpad
B $BFDB,32,h8
c $BFFB
@ $BFFB label=chk_pickup_drop
C $BFFB,h3
C $BFFF,h2
C $C001,h3
C $C004,h2
C $C008,h2
c $C00B
@ $C00B label=loc_C00B
C $C00B,h2
c $C00E
@ $C00E label=handle_pickup_drop
C $C00E,h3
C $C012,h3
C $C015,h3
C $C019,h3
C $C01D,h4
C $C022,h4
C $C028,h3
C $C02B,h3
C $C02F,h2
C $C031,h6
C $C037,h3
C $C03A,h2
C $C03C,h2
C $C03E,h3
c $C041
@ $C041 label=loc_C041
C $C041,h13
C $C04E,h3
C $C052,h2
C $C054,h3
C $C057,h3
C $C05B,h2
C $C05D,h3
C $C061,h3
C $C065,h2
C $C067,8,h3,1,h4
c $C06F
@ $C06F label=loc_C06F
C $C06F,h3
C $C072,h3
C $C075,h3
C $C07A,h9
C $C083,h3
C $C086,h2
C $C088,h2
C $C08A,h2
c $C08C
@ $C08C label=loc_C08C
C $C08C,h4
C $C090,h3
c $C093
@ $C093 label=loc_C093
C $C093,h3
C $C097,h2
C $C09B,h2
c $C09D
@ $C09D label=done_pickup_drop
C $C09E,h3
C $C0A2,h3
C $C0A5,h3
c $C0A9
@ $C0A9 label=loc_C0A9
C $C0A9,h3
C $C0AE,h3
c $C0B2
@ $C0B2 label=room_to_drop
C $C0B2,14,h3,3,h5,1,h2
C $C0C3,h3
C $C0C6,h3
C $C0C9,h2
C $C0CB,h2
C $C0CD,h3
C $C0D0,h4
C $C0D4,h4
C $C0D8,h5
c $C0DD
@ $C0DD label=loc_C0DD
C $C0DE,h3
C $C0EB,h3
C $C0EE,h2
C $C0F0,h3
C $C0F3,h3
C $C0F6,h2
C $C0F8,h3
C $C101,h3
c $C106
@ $C106 label=drop_object
C $C106,hh4
C $C10A,hh4
C $C10E,hh4
C $C115,h3
C $C118,h3
C $C11B,8,h3,2,h3
C $C124,h3
C $C127,h4
c $C12B
@ $C12B label=adjust_carried
C $C12B,h3
C $C12E,h6
C $C136,h5
C $C13B,h6
c $C141
@ $C141 label=pickup_object
C $C141,7,h3,1,h3
C $C148,h3
C $C14D,h3
C $C152,h3
C $C155,h3
C $C15D,7,h3,hh4
C $C164,h3
C $C16A,8,h5,1,h2
c $C172
@ $C172 label=can_pickup_spec_obj
C $C172,h3
C $C175,h2
C $C177,h2
c $C17A
@ $C17A label=is_on_or_near_obj
C $C17B,15,h3,2,h10
C $C18A,h3
C $C18D,h2
C $C18F,15,h6,1,h8
c $C19F
@ $C19F label=loc_C19F
c $C1A1
@ $C1A1 label=is_obj_moving
C $C1A1,h3
C $C1A4,h3
C $C1A7,h3
c $C1AB
@ $C1AB label=upd_103
C $C1AB,h3
C $C1B2,h4
C $C1B6,h3
C $C1B9,h3
C $C1BC,h3
C $C1BF,h3
C $C1C2,h3
C $C1C9,h2
C $C1CB,h4
C $C1CF,h9
C $C1D8,h2
C $C1DA,h3
C $C1DF,h15
c $C1EE
@ $C1EE label=loc_C1EE
C $C1EE,h3
c $C1F1
@ $C1F1 label=upd_104_to_110
C $C1F1,h3
C $C1F4,h3
C $C1F7,h9
c $C202
@ $C202 label=loc_C202
C $C202,h3
C $C205,h3
C $C208,h9
c $C213
@ $C213 label=loc_C213
C $C213,h3
C $C216,h3
C $C219,h2
C $C21B,h2
C $C21D,h3
C $C220,h2
c $C222
@ $C222 label=loc_C222
C $C222,h9
c $C22C
@ $C22C label=loc_C22C
C $C22C,h3
c $C22F
@ $C22F label=loc_C22F
C $C22F,h3
c $C232
@ $C232 label=audio_B467_wipe_and_draw
C $C232,h6
c $C238
@ $C238 label=centre_of_room
C $C238,h2
C $C23A,h3
C $C23D,h2
C $C23F,h4
C $C243,h2
c $C245
@ $C245 label=add_obj_to_cauldron
C $C245,7,hh4,h3
C $C24C,h3
C $C24F,h2
C $C252,12,h5,1,h6
C $C25E,h2
C $C260,h5
c $C265
@ $C265 label=loc_C265
C $C266,h6
C $C26C,h3
C $C26F,h2
C $C271,h3
c $C274
@ $C274 label=ret_next_obj_required
C $C274,h9
b $C27D
@ $C27D label=objects_required
B $C27D,14,h7
c $C28B
@ $C28B label=upd_96_to_102
C $C28B,h6
C $C291,h4
C $C295,h5
c $C29B
@ $C29B label=loc_C29B
C $C29B,h10
c $C2A5
@ $C2A5 label=cycle_colours_with_sound
C $C2A5,h2
c $C2A7
@ $C2A7 label=loc_C2A7
C $C2A7,h3
C $C2AA,h3
c $C2AD
@ $C2AD label=cycle_attribute_mem
C $C2AE,21,h2,3,h2,6,h8
c $C2C3
@ $C2C3 label=loc_C2C3
C $C2C6,5,h2,1,h2
c $C2CB
@ $C2CB label=no_update
c $C2CC
@ $C2CC label=prepare_final_animation
C $C2CC,h5
C $C2D3,h4
C $C2D7,h3
C $C2DA,h2
c $C2DC
@ $C2DC label=loc_C2DC
C $C2DE,h3
C $C2E3,hh4
C $C2E9,h5
c $C2EE
@ $C2EE label=loc_C2EE
C $C2EE,h3
C $C2F1,h2
C $C2F3,h2
C $C2F5,hh4
c $C2F9
@ $C2F9 label=loc_C2F9
C $C301,h2
c $C306
@ $C306 label=chk_and_init_transform
C $C306,10,h3,2,h5
C $C311,h4
C $C318,h3
C $C31B,h3
C $C31E,hh4
C $C324,h3
C $C329,14,hh4,h3,2,h5
c $C337
@ $C337 label=upd_92_to_95
C $C337,18,h12,1,h5
c $C349
@ $C349 label=loc_C349
C $C349,h3
C $C34C,h2
C $C34F,h3
C $C352,h3
C $C355,h2
c $C357
@ $C357 label=rand_legs_sprite
C $C35A,6,h3,1,h2
C $C360,h2
C $C362,h3
C $C365,h2
C $C367,h2
c $C369
@ $C369 label=loc_C369
C $C369,h6
C $C36F,h2
C $C371,h6
c $C377
@ $C377 label=loc_C377
C $C377,h3
C $C37A,h2
C $C37C,h3
C $C37F,h2
C $C381,h3
C $C385,h12
C $C391,h3
c $C394
@ $C394 label=loc_C394
C $C394,h3
c $C397
@ $C397 label=print_sun_moon
C $C397,10,h5,1,h4
C $C3A1,h3
c $C3A4
@ $C3A4 label=display_sun_moon_frame
C $C3A4,h3
C $C3A9,h3
C $C3AC,h4
C $C3B0,h3
C $C3B3,9,h5,2,h2
C $C3BC,h3
C $C3C0,h3
c $C3C3
@ $C3C3 label=display_frame
C $C3C3,h3
C $C3C6,12,h3,6,h3
C $C3D2,h7
C $C3D9,hh4
C $C3DD,hh4
C $C3E1,hh4
C $C3E5,hh4
C $C3E9,h3
C $C3EC,hh4
C $C3F0,hh4
C $C3F4,h3
C $C3F9,h6
c $C3FF
@ $C3FF label=toggle_day_night
C $C3FF,h3
C $C402,h2
C $C404,h6
C $C40A,hh4
C $C40E,h10
c $C419
@ $C419 label=inc_days
C $C419,16,h3,1,h2,2,h8
C $C429,h3
C $C42C,h6
c $C432
@ $C432 label=blit_2x8
C $C432,14,h6,2,h6
b $C440
@ $C440 label=sun_moon_yoff
B $C440,13,h8,h5
b $C44D
@ $C44D label=sun_moon_scratchpad
B $C44D,32,h8
c $C46D
@ $C46D label=init_sun
C $C46D,h4
C $C471,hh4
C $C475,hh4
C $C479,hh4
c $C47E
@ $C47E label=init_special_objects
C $C47E,h6
c $C489
@ $C489 label=init_obj_loop
C $C48A,h4
C $C493,h3
C $C498,h3
C $C49F,h3
C $C4A7,h2
c $C4AA
@ $C4AA label=upd_62
C $C4AA,h12
c $C4B6
@ $C4B6 label=upd_85
C $C4B6,h9
C $C4C0,h3
c $C4C3
@ $C4C3 label=upd_84
C $C4C3,h3
c $C4C6
@ $C4C6 label=dec_dZ_upd_XYZ_wipe_if_moving
C $C4C6,13,h6,1,h6
c $C4D3
@ $C4D3 label=upd_128_to_130
C $C4D3,h3
C $C4D6,h2
c $C4D8
@ $C4D8 label=adj_m4_m12
C $C4D8,h3
C $C4DB,h2
c $C4DD
@ $C4DD label=adj_m6_m12
C $C4DD,h3
c $C4E0
@ $C4E0 label=jp_set_pixel_adj
C $C4E0,h3
c $C4E3
@ $C4E3 label=upd_6_7
C $C4E3,h3
C $C4E6,h2
c $C4E8
@ $C4E8 label=upd_10
C $C4E8,h5
c $C4ED
@ $C4ED label=upd_11
C $C4ED,h3
C $C4F0,h2
c $C4F2
@ $C4F2 label=upd_12_to_15
C $C4F2,h3
C $C4F5,h2
c $C4F7
@ $C4F7 label=adj_m8_m12
C $C4F7,h3
C $C4FA,h2
c $C4FC
@ $C4FC label=adj_m7_m12
C $C4FC,h3
C $C4FF,h2
c $C501
@ $C501 label=adj_m12_m12
C $C501,h3
C $C504,h2
c $C506
@ $C506 label=upd_88_to_90
C $C506,h5
c $C50B
@ $C50B label=adj_p7_m12
C $C50B,h3
C $C50E,h2
c $C510
@ $C510 label=adj_p3_m12
C $C510,h3
C $C513,h2
c $C515
@ $C515 label=fill_window
C $C515,h3
c $C518
@ $C518 label=loc_C518
c $C51A
@ $C51A label=loc_C51A
C $C51C,h2
C $C522,h2
c $C525
@ $C525 label=find_special_objs_here
C $C525,8,h3,1,h4
C $C52D,h3
c $C530
@ $C530 label=loc_C530
C $C530,h3
C $C534,h2
C $C536,h3
C $C53A,h2
C $C549,h3
C $C54F,h2
C $C552,h2
C $C555,h2
C $C558,h2
C $C560,h5
C $C56C,h5
c $C572
@ $C572 label=loc_C572
C $C572,h3
C $C57A,h3
C $C580,h2
c $C583
@ $C583 label=loc_C583
C $C583,h3
C $C58A,h2
C $C58C,h3
C $C58F,h2
c $C591
@ $C591 label=update_special_objs
C $C591,h4
c $C595
@ $C595 label=loc_C595
C $C595,h3
C $C599,h5
C $C59E,h3
C $C5A1,h3
C $C5AE,h3
C $C5B3,h3
c $C5B7
@ $C5B7 label=loc_C5B7
C $C5B7,h3
C $C5BF,h3
C $C5C5,h2
c $C5C8
@ $C5C8 label=upd_80_to_83
C $C5C8,h6
C $C5CE,h3
C $C5D1,h3
C $C5D4,h5
C $C5D9,h2
C $C5DB,h2
c $C5DD
@ $C5DD label=loc_C5DD
C $C5DD,h5
C $C5E2,h2
C $C5E4,h3
C $C5E7,h3
C $C5EA,h5
C $C5EF,h2
C $C5F1,h3
C $C5F4,h3
C $C5F7,h6
c $C5FD
@ $C5FD label=loc_C5FD
C $C5FD,h6
c $C603
@ $C603 label=calc_ghost_sprite
C $C603,h3
C $C607,h3
c $C60C
@ $C60C label=loc_C60C
C $C60D,h3
C $C611,h3
c $C616
@ $C616 label=loc_C616
C $C617,h2
C $C619,h3
C $C61D,h3
C $C620,h4
c $C624
@ $C624 label=set_ghost_hflip
C $C624,h4
c $C629
@ $C629 label=loc_C629
C $C629,h6
c $C62F
@ $C62F label=loc_C62F
C $C62F,h3
C $C633,h3
C $C636,h4
c $C63A
@ $C63A label=clr_ghost_hflip
C $C63A,h4
c $C63F
@ $C63F label=loc_C63F
C $C63F,h6
c $C645
@ $C645 label=get_delta_from_tbl
C $C645,6,h3,1,h2
b $C64E
@ $C64E label=delta_tbl
B $C64E,16,h2
c $C65E
@ $C65E label=upd_8
C $C65E,h6
C $C667,h3
C $C66A,h3
C $C66D,h4
C $C671,h3
C $C674,h5
C $C679,h2
C $C67B,h5
C $C680,h2
C $C683,h2
c $C685
@ $C685 label=init_portcullis_down
C $C686,h3
C $C689,h4
C $C68D,hh4
c $C691
@ $C691 label=loc_C691
c $C692
@ $C692 label=set_wipe_and_draw_flags
C $C692,h3
C $C695,h2
C $C697,h6
c $C69D
@ $C69D label=set_wipe_and_draw_IY
C $C6A5,h3
c $C6AD
@ $C6AD label=init_portcullis_up
C $C6AD,h3
C $C6B0,h2
C $C6B3,h4
C $C6B7,hh4
C $C6BB,h2
c $C6BD
@ $C6BD label=upd_9
C $C6BD,h3
C $C6C0,h4
C $C6C4,h3
C $C6C7,h2
C $C6CA,h3
C $C6CE,h3
C $C6D1,h3
C $C6D4,h3
C $C6D7,h4
C $C6DB,h5
c $C6E0
@ $C6E0 label=stop_portcullis
C $C6E1,h3
C $C6E4,h4
C $C6E8,h2
c $C6EA
@ $C6EA label=move_portcullis_up
C $C6EA,15,hh4,h11
C $C6F9,h3
C $C6FC,h4
c $C700
@ $C700 label=dec_dZ_and_update_XYZ
C $C700,h3
C $C703,h3
c $C706
@ $C706 label=add_dXYZ
C $C706,h3
C $C709,h3
C $C70C,h3
C $C70F,h3
C $C712,h3
C $C715,h3
C $C718,h3
C $C71B,h3
C $C71E,h3
c $C722
@ $C722 label=upd_3_5
C $C722,h4
C $C726,h2
C $C728,h3
c $C72B
@ $C72B label=set_pixel_adj
C $C72B,h3
C $C72E,h3
c $C732
@ $C732 label=adj_3_5_hflip
C $C732,h5
c $C737
@ $C737 label=adj_m3_p1
C $C737,h5
c $C73C
@ $C73C label=upd_2_4
C $C73C,h4
C $C740,h2
C $C742,h3
C $C745,h2
C $C747,h2
C $C749,h3
c $C74C
@ $C74C label=loc_C74C
C $C74C,h3
C $C74F,h3
C $C752,h2
C $C754,h3
C $C757,h3
C $C75A,h3
C $C75D,h3
c $C760
@ $C760 label=loc_C760
C $C760,h3
C $C763,h3
C $C766,h6
c $C76C
@ $C76C label=adj_2_4_hflip
C $C76C,h6
C $C772,h3
C $C775,h2
C $C777,h3
C $C77A,h3
C $C77D,h3
C $C780,h3
C $C783,h2
c $C785
@ $C785 label=loc_C785
C $C785,h7
C $C78C,h3
C $C78F,h2
c $C791
@ $C791 label=loc_C791
C $C791,h3
C $C795,17,h13,1,h3
C $C7A6,h3
b $C7A9
@ $C7A9 label=adj_arch_tbl
W $C7A9,8,h2
c $C7B1
@ $C7B1 label=adj_ew
C $C7B1,h3
C $C7B4,h3
C $C7B7,h6
c $C7BF
@ $C7BF label=loc_C7BF
C $C7BF,h5
c $C7C4
@ $C7C4 label=adj_ns
C $C7C4,h3
C $C7C7,h3
C $C7CA,h6
c $C7D2
@ $C7D2 label=loc_C7D2
C $C7D2,h3
c $C7D5
@ $C7D5 label=loc_C7D5
c $C7D6
@ $C7D6 label=loc_C7D6
C $C7D8,h2
c $C7DB
@ $C7DB label=chk_plyr_spec_near_arch
C $C7DB,h4
C $C7DF,h3
C $C7E2,h2
c $C7E4
@ $C7E4 label=loc_C7E4
C $C7E4,h3
C $C7E8,h2
C $C7EA,h4
C $C7EE,h5
C $C7F3,h2
C $C7F5,h4
c $C7F9
@ $C7F9 label=loc_C7F9
C $C7FB,h2
c $C7FE
@ $C7FE label=is_near_to
C $C7FE,h3
C $C801,h3
C $C804,h2
c $C808
@ $C808 label=loc_C808
C $C80A,h3
C $C80D,h3
C $C810,h2
c $C814
@ $C814 label=loc_C814
C $C816,h3
C $C819,h3
C $C81C,h2
c $C820
@ $C820 label=loc_C820
C $C820,h2
c $C823
@ $C823 label=upd_16_to_21_24_to_29
C $C823,h5
c $C828
@ $C828 label=upd_48_to_53_56_to_61
C $C828,h3
c $C82B
@ $C82B label=upd_player_bottom
C $C82B,h4
C $C82F,8,h5,1,h2
C $C837,h4
C $C83B,h3
c $C83E
@ $C83E label=loc_C83E
C $C83E,h23
c $C855
@ $C855 label=loc_C855
C $C855,h4
C $C859,h3
C $C85C,h4
C $C860,h3
C $C863,h2
C $C865,h2
C $C867,h3
c $C86A
@ $C86A label=loc_C86A
C $C86A,h3
c $C86D
@ $C86D label=plyr_OOB
C $C86D,h3
C $C871,h3
C $C875,h3
C $C878,h2
c $C87A
@ $C87A label=chk_plyr_OOB
C $C87A,h3
C $C87E,h3
C $C883,h3
C $C887,h3
C $C88A,h5
c $C891
@ $C891 label=loc_C891
C $C893,h3
C $C896,h5
c $C89D
@ $C89D label=loc_C89D
c $C89F
@ $C89F label=handle_left_right
C $C89F,h3
C $C8A3,h2
C $C8A5,h2
C $C8A9,h2
C $C8AB,h3
C $C8AE,h2
C $C8B1,h4
C $C8B8,h2
C $C8BC,h2
c $C8BE
@ $C8BE label=loc_C8BE
C $C8C0,h2
C $C8C4,h2
C $C8C8,h2
c $C8CD
@ $C8CD label=chk_facing_N
C $C8CD,h3
C $C8D0,h2
c $C8D2
@ $C8D2 label=loc_C8D2
C $C8D2,h2
c $C8D5
@ $C8D5 label=loc_C8D5
C $C8D5,h4
c $C8D9
@ $C8D9 label=chk_facing_E
C $C8D9,h3
C $C8DC,h2
C $C8DE,h2
c $C8E0
@ $C8E0 label=chk_facing_S
C $C8E0,h3
C $C8E3,h2
c $C8E5
@ $C8E5 label=loc_C8E5
C $C8E5,h4
c $C8E9
@ $C8E9 label=chk_facing_W
C $C8E9,h3
C $C8ED,h2
c $C8EF
@ $C8EF label=flag_forward
c $C8F2
@ $C8F2 label=left_right_rotational
C $C8F2,h3
C $C8F5,h2
C $C8F7,h2
C $C8F9,h3
c $C8FD
@ $C8FD label=loc_C8FD
C $C8FE,h2
C $C901,h3
C $C904,h2
C $C907,h4
C $C90E,6,h2,1,h3
c $C915
@ $C915 label=loc_C915
C $C915,h3
C $C918,h2
C $C91A,h3
c $C91F
@ $C91F label=left_right_calc_sprite
C $C91F,h2
C $C921,h4
C $C925,h2
c $C927
@ $C927 label=loc_C927
C $C927,h8
c $C92F
@ $C92F label=loc_C92F
C $C92F,h3
C $C932,h2
C $C934,h3
C $C937,h3
C $C93A,h2
C $C93C,h3
c $C940
@ $C940 label=loc_C940
C $C940,h4
C $C944,h4
c $C948
@ $C948 label=handle_jump
C $C94B,h3
C $C94E,h2
C $C951,h4
C $C956,h3
C $C95B,h4
C $C95F,hh4
C $C964,h3
c $C969
@ $C969 label=handle_forward
C $C969,h3
C $C96C,h2
C $C96E,h2
C $C970,h4
C $C974,h2
C $C978,h2
c $C97A
@ $C97A label=loc_C97A
C $C97B,h3
c $C97F
@ $C97F label=animate_human_legs
C $C97F,h3
C $C984,h2
C $C986,h2
C $C988,h2
c $C98B
@ $C98B label=loc_C98B
C $C98D,h2
C $C990,h3
c $C994
@ $C994 label=loc_C994
C $C994,13,h7,1,h2,1,h2
c $C9A1
@ $C9A1 label=move_player
C $C9A1,6,h3,1,h2
C $C9A7,hh4
c $C9AB
@ $C9AB label=loc_C9AB
C $C9AB,h4
C $C9AF,h2
C $C9B1,h3
C $C9B4,h2
C $C9B6,h2
C $C9BA,h2
c $C9BC
@ $C9BC label=loc_C9BC
C $C9BD,h3
c $C9C1
@ $C9C1 label=loc_C9C1
C $C9C1,7,h3,1,h3
C $C9CA,h2
c $C9CC
@ $C9CC label=loc_C9CC
c $C9CD
@ $C9CD label=loc_C9CD
C $C9CE,h3
C $C9D1,h17
C $C9E2,h4
C $C9E6,9,h5,1,h3
C $C9EF,h4
c $C9F3
@ $C9F3 label=clear_dX_dY
C $C9F4,h3
C $C9F7,h3
c $C9FB
@ $C9FB label=calc_plyr_dXY
C $C9FB,h3
C $C9FE,h3
C $CA01,h3
C $CA04,h3
C $CA07,h3
C $CA0A,h3
C $CA0E,h3
C $CA11,h3
C $CA14,h3
c $CA17
@ $CA17 label=lookup_plyr_dXY
C $CA17,7,h3,1,h3
c $CA1E
@ $CA1E label=get_sprite_dir
C $CA1E,h3
C $CA23,h2
C $CA26,h3
C $CA29,h2
C $CA2F,h2
b $CA32
@ $CA32 label=off_CA32
W $CA32,2,h2
W $CA34,2,h2
W $CA36,2,h2
W $CA38,2,h2
c $CA3A
@ $CA3A label=move_plyr_W
C $CA3A,h3
C $CA3D,h2
c $CA3F
@ $CA3F label=loc_CA3F
C $CA3F,h3
c $CA43
@ $CA43 label=move_plyr_E
C $CA43,h3
C $CA46,h2
C $CA48,h2
c $CA4A
@ $CA4A label=move_plyr_N
C $CA4A,h3
C $CA4D,h2
c $CA4F
@ $CA4F label=loc_CA4F
C $CA4F,h3
c $CA53
@ $CA53 label=move_plyr_S
C $CA53,h3
C $CA56,h2
C $CA58,h2
c $CA5A
@ $CA5A label=adj_dZ_for_out_of_bounds
C $CA5A,h3
c $CA5E
@ $CA5E label=loc_CA5E
C $CA5E,h3
C $CA64,h4
C $CA69,h3
C $CA6D,h2
c $CA70
@ $CA70 label=handle_exit_screen
C $CA70,h3
C $CA73,h2
C $CA76,h4
C $CA7B,h4
C $CA7F,10,h6,1,h3
c $CA89
@ $CA89 label=adj_d_for_out_of_bounds
C $CA8B,h3
c $CA90
@ $CA90 label=loc_CA90
b $CA92
@ $CA92 label=screen_move_tbl
W $CA92,8,h2
c $CA9A
@ $CA9A label=screen_west
C $CA9B,h2
C $CA9F,h3
C $CAA2,h3
C $CAA5,h3
C $CAAA,hh4
C $CAAE,h3
c $CAB3
@ $CAB3 label=screen_e_w
C $CAB3,h2
C $CAB7,h2
c $CABA
@ $CABA label=exit_screen
C $CABA,h3
C $CABD,h3
C $CAC0,h2
C $CAC2,h3
C $CAC5,h3
C $CAC8,h2
C $CACA,h2
C $CAD4,h6
C $CADC,h6
C $CAE2,h6
C $CAE8,h2
C $CAEA,h3
C $CAED,h6
c $CAF3
@ $CAF3 label=screen_east
C $CAF5,h2
C $CAF8,h3
C $CAFB,h3
C $CAFE,h3
C $CB03,hh4
C $CB07,h3
C $CB0C,h2
c $CB0E
@ $CB0E label=screen_north
C $CB10,h2
C $CB13,h3
C $CB16,h3
C $CB19,h3
C $CB1E,hh4
C $CB22,h3
C $CB25,h2
C $CB27,h2
c $CB29
@ $CB29 label=screen_south
C $CB2A,h2
C $CB2E,h3
C $CB31,h3
C $CB34,h3
C $CB39,hh4
C $CB3D,h3
C $CB40,h2
C $CB42,h3
c $CB45
@ $CB45 label=adj_for_out_of_bounds
C $CB45,12,h4,1,h7
C $CB51,h2
C $CB53,h5
C $CB59,h3
C $CB5E,h5
C $CB65,h5
c $CB6A
@ $CB6A label=dZ_ok
C $CB6A,h3
C $CB6F,h5
C $CB76,h5
c $CB7B
@ $CB7B label=loc_CB7B
C $CB7B,h3
C $CB80,h5
C $CB87,h5
c $CB8C
@ $CB8C label=loc_CB8C
C $CB8C,h3
C $CB8F,h3
C $CB92,h3
C $CB95,h4
c $CB9A
@ $CB9A label=adj_dX_for_obj_intersect
C $CB9A,h4
C $CB9E,h2
c $CBA0
@ $CBA0 label=loc_CBA0
C $CBA0,h3
C $CBA3,h12
c $CBAF
@ $CBAF label=loc_CBAF
C $CBAF,h5
C $CBB4,h4
C $CBB8,h3
C $CBBC,h2
C $CBBE,h3
C $CBC1,h3
C $CBC5,h2
C $CBC7,h3
C $CBCA,h3
C $CBCD,h4
C $CBD1,h5
C $CBD6,h3
c $CBD9
@ $CBD9 label=loc_CBD9
C $CBDA,7,h3,2,h2
c $CBE1
@ $CBE1 label=loc_CBE1
C $CBE1,h3
C $CBE6,h2
c $CBE9
@ $CBE9 label=adj_dY_for_obj_intersect
C $CBE9,h4
C $CBED,h2
c $CBEF
@ $CBEF label=loc_CBEF
C $CBEF,h3
C $CBF2,h5
C $CBF7,h5
C $CBFC,h2
c $CBFE
@ $CBFE label=loc_CBFE
C $CBFE,h3
C $CC01,h2
C $CC03,h4
C $CC07,h3
C $CC0B,h2
C $CC0D,h3
C $CC10,h3
C $CC14,h2
C $CC16,h3
C $CC19,h3
C $CC1C,h4
C $CC20,h5
C $CC25,h3
c $CC28
@ $CC28 label=loc_CC28
C $CC29,7,h3,2,h2
c $CC30
@ $CC30 label=loc_CC30
C $CC30,h3
C $CC35,h2
c $CC38
@ $CC38 label=adj_dZ_for_obj_intersect
C $CC38,h4
C $CC3C,h2
c $CC3E
@ $CC3E label=loc_CC3E
C $CC3E,h3
C $CC41,h5
C $CC46,h5
C $CC4B,h2
c $CC4D
@ $CC4D label=loc_CC4D
C $CC4D,h3
C $CC50,h2
C $CC52,h4
C $CC56,h3
C $CC5A,h2
C $CC5C,h3
C $CC5F,h3
C $CC63,h2
C $CC65,h3
C $CC68,h3
C $CC6B,h4
C $CC6F,h4
C $CC73,h2
C $CC75,h3
C $CC79,h5
C $CC7E,h3
c $CC81
@ $CC81 label=loc_CC81
C $CC81,h3
C $CC85,h5
C $CC8A,h3
c $CC8D
@ $CC8D label=loc_CC8D
C $CC8E,7,h3,2,h2
c $CC95
@ $CC95 label=loc_CC95
C $CC95,h3
C $CC9A,h2
c $CC9D
@ $CC9D label=do_objs_intersect_on_x
C $CC9D,h3
C $CCA0,h3
C $CCA4,h3
C $CCA8,h3
C $CCAB,h3
c $CCB0
@ $CCB0 label=loc_CCB0
c $CCB2
@ $CCB2 label=do_objs_intersect_on_y
C $CCB2,h3
C $CCB5,h3
C $CCB9,h3
C $CCBD,h3
C $CCC0,h3
c $CCC5
@ $CCC5 label=loc_CCC5
c $CCC7
@ $CCC7 label=do_objs_intersect_on_z
C $CCC7,h3
C $CCCB,h3
C $CCCE,h3
C $CCD3,h3
c $CCD6
@ $CCD6 label=loc_CCD6
c $CCD8
@ $CCD8 label=loc_CCD8
C $CCD8,h5
c $CCDD
@ $CCDD label=adj_dX_for_out_of_bounds
C $CCDD,h3
C $CCE0,h2
C $CCE3,h4
C $CCE8,h3
c $CCEC
@ $CCEC label=loc_CCEC
C $CCEC,h3
C $CCF0,h4
c $CCF6
@ $CCF6 label=loc_CCF6
C $CCF6,h3
C $CCFA,h2
C $CCFC,h4
C $CD01,h3
C $CD05,h2
c $CD07
@ $CD07 label=dX_ok
c $CD08
@ $CD08 label=adj_dY_for_out_of_bounds
C $CD08,h3
C $CD0B,h2
C $CD0E,h4
C $CD13,h3
c $CD17
@ $CD17 label=loc_CD17
C $CD17,h3
C $CD1B,h4
c $CD21
@ $CD21 label=loc_CD21
C $CD21,h3
C $CD25,h2
C $CD27,h4
C $CD2C,h3
C $CD30,h2
c $CD32
@ $CD32 label=dY_ok
c $CD33
@ $CD33 label=calc_2d_info
C $CD33,h6
C $CD39,h3
C $CD3C,h2
C $CD40,h2
c $CD43
@ $CD43 label=loc_CD43
C $CD43,h2
C $CD45,h3
C $CD49,h3
c $CD4D
@ $CD4D label=set_draw_objs_overlapped
C $CD4D,h7
C $CD54,h2
C $CD56,h3
C $CD5C,h2
C $CD5F,h3
C $CD65,h2
C $CD69,h2
c $CD6C
@ $CD6C label=loc_CD6C
C $CD6E,h3
C $CD73,h3
C $CD77,h2
c $CD7A
@ $CD7A label=loc_CD7A
C $CD7C,h3
C $CD7F,h3
C $CD82,h2
C $CD84,h3
c $CD87
@ $CD87 label=loc_CD87
C $CD88,h3
C $CD8B,h3
C $CD8F,h3
C $CD92,h3
C $CD96,h2
c $CD99
@ $CD99 label=loc_CD99
c $CD9B
@ $CD9B label=test_overlap_obj
C $CD9B,h3
C $CD9F,h2
C $CDA1,h4
C $CDA5,h2
C $CDA7,h3
C $CDAD,h2
C $CDB0,h2
c $CDB3
@ $CDB3 label=loc_CDB3
C $CDB3,h2
C $CDB5,h3
C $CDB9,h2
c $CDBC
@ $CDBC label=loc_CDBC
C $CDBC,h2
C $CDBE,h4
c $CDC2
@ $CDC2 label=next_overlap_obj
C $CDC3,h3
C $CDC9,h2
c $CDCC
@ $CDCC label=loc_CDCC
C $CDCE,h3
C $CDD1,h2
c $CDD3
@ $CDD3 label=loc_CDD3
C $CDD5,h3
C $CDD8,h2
c $CDDA
@ $CDDA label=upd_32_to_47
C $CDDA,h5
c $CDDF
@ $CDDF label=upd_64_to_79
C $CDDF,h3
c $CDE2
@ $CDE2 label=upd_player_top
C $CDE2,13,h3,1,h9
c $CDEF
@ $CDEF label=loc_CDEF
C $CDF2,h3
C $CDFB,h3
C $CE00,hh4
C $CE04,h4
C $CE08,h3
C $CE0B,h2
C $CE0D,h2
C $CE0F,h3
C $CE12,h2
c $CE14
@ $CE14 label=loc_CE14
C $CE14,h3
C $CE17,h2
C $CE19,h2
C $CE1B,h2
C $CE1D,h2
C $CE1F,h3
c $CE22
@ $CE22 label=set_top_sprite
C $CE22,h2
C $CE24,h3
c $CE27
@ $CE27 label=loc_CE27
C $CE27,h3
C $CE2A,h2
C $CE2C,h3
C $CE2F,h3
c $CE33
@ $CE33 label=loc_CE33
C $CE33,h5
C $CE38,h2
c $CE3A
@ $CE3A label=loc_CE3A
C $CE3A,6,hh4,h2
c $CE40
@ $CE40 label=loc_CE40
C $CE40,h5
C $CE45,h2
C $CE47,h2
c $CE49
@ $CE49 label=save_2d_info
C $CE49,h3
C $CE4C,h3
C $CE4F,h3
C $CE52,h3
C $CE55,h3
C $CE58,h3
C $CE5B,h3
C $CE5E,h3
c $CE62
@ $CE62 label=list_objects_to_draw
C $CE64,h2
C $CE66,h3
C $CE69,h7
C $CE70,h2
c $CE72
@ $CE72 label=loc_CE72
C $CE72,h3
C $CE76,h2
C $CE78,h4
C $CE7C,h2
c $CE80
@ $CE80 label=loc_CE80
C $CE83,h4
b $CE8B
@ $CE8B label=objects_to_draw
B $CE8B,48,h8
c $CEBB
@ $CEBB label=calc_display_order_and_render
C $CEBC,h3
c $CEC3
@ $CEC3 label=process_remaining_objs
C $CEC3,h3
c $CEC6
@ $CEC6 label=loc_CEC6
C $CEC8,h2
C $CECA,h3
C $CECF,h2
C $CED1,h7
c $CEDB
@ $CEDB label=loc_CEDB
C $CEDD,h2
C $CEDF,14,h3,2,h9
C $CEF6,h4
C $CEFA,h3
C $CEFD,h3
C $CF01,h3
C $CF05,h2
C $CF07,h3
C $CF0A,h3
C $CF0E,h3
C $CF12,h2
c $CF15
@ $CF15 label=loc_CF15
c $CF16
@ $CF16 label=loc_CF16
C $CF16,h3
C $CF19,h3
C $CF1D,h3
C $CF20,h3
C $CF24,h2
C $CF26,h3
C $CF29,h3
C $CF2D,h3
C $CF30,h3
C $CF35,h2
C $CF37,h2
c $CF39
@ $CF39 label=loc_CF39
C $CF39,h2
c $CF3C
@ $CF3C label=loc_CF3C
C $CF3C,h3
C $CF3F,h3
C $CF43,h3
C $CF46,h3
C $CF4A,h2
C $CF4C,h3
C $CF4F,h3
C $CF53,h3
C $CF56,h3
C $CF5B,h2
C $CF5D,h2
c $CF5F
@ $CF5F label=loc_CF5F
C $CF5F,h2
c $CF62
@ $CF62 label=loc_CF62
C $CF63,h6
b $CF69
@ $CF69 label=off_CF69
W $CF69,2,h2
W $CF6B,2,h2
W $CF6D,2,h2
W $CF6F,2,h2
W $CF71,2,h2
W $CF73,2,h2
W $CF75,2,h2
W $CF77,2,h2
W $CF79,2,h2
W $CF7B,2,h2
W $CF7D,2,h2
W $CF7F,2,h2
W $CF81,2,h2
W $CF83,2,h2
W $CF85,2,h2
W $CF87,2,h2
W $CF89,2,h2
W $CF8B,2,h2
W $CF8D,2,h2
W $CF8F,2,h2
W $CF91,2,h2
W $CF93,2,h2
W $CF95,2,h2
W $CF97,2,h2
W $CF99,2,h2
W $CF9B,2,h2
W $CF9D,2,h2
c $CF9F
@ $CF9F label=continue_1
C $CF9F,h3
c $CFA2
@ $CFA2 label=continue_2
C $CFA2,h3
c $CFA5
@ $CFA5 label=d_3467121516
C $CFA5,h3
C $CFAA,h3
c $CFAD
@ $CFAD label=loc_CFAD
C $CFAE,h2
C $CFB0,h2
C $CFB3,h2
C $CFB6,h2
c $CFB8
@ $CFB8 label=loc_CFB8
C $CFBB,h2
C $CFC2,h3
C $CFC5,h6
C $CFCB,h3
c $CFCE
@ $CFCE label=loc_CFCE
C $CFCE,h3
c $CFD1
@ $CFD1 label=loc_CFD1
C $CFD3,h2
C $CFD5,h3
C $CFD9,h2
C $CFDF,h2
c $CFE1
@ $CFE1 label=objs_coincide
C $CFE1,h5
C $CFE6,h2
C $CFE8,h2
C $CFEA,hh4
C $CFEE,h2
c $CFF0
@ $CFF0 label=loc_CFF0
C $CFF0,h5
C $CFF5,h2
C $CFF7,h2
C $CFF9,hh4
c $CFFD
@ $CFFD label=loc_CFFD
C $CFFD,h3
c $D000
@ $D000 label=render_obj_no1
C $D000,h3
c $D003
@ $D003 label=render_obj
C $D006,h2
C $D008,h6
C $D00F,h3
C $D012,h3
c $D015
@ $D015 label=render_done
b $D01A
@ $D01A label=render_list
B $D01A,8,h1
c $D022
@ $D022 label=check_user_input
C $D022,16,h3,1,h3,1,h8
C $D033,h2
C $D035,9,h3,1,h2,1,h2
c $D03E
@ $D03E label=interface_ii
C $D03E,h2
C $D040,h3
C $D044,h2
c $D046
@ $D046 label=loc_D046
C $D049,h2
C $D04E,h2
C $D050,h3
C $D054,h2
C $D058,h2
c $D05C
@ $D05C label=loc_D05C
C $D05E,h2
c $D062
@ $D062 label=loc_D062
C $D064,h2
c $D068
@ $D068 label=loc_D068
C $D06A,h2
c $D06E
@ $D06E label=loc_D06E
C $D070,h2
c $D074
@ $D074 label=loc_D074
C $D074,h3
c $D077
@ $D077 label=kempston
C $D077,h4
C $D07D,h2
c $D081
@ $D081 label=loc_D081
C $D083,h2
c $D087
@ $D087 label=loc_D087
C $D089,h2
c $D08D
@ $D08D label=loc_D08D
C $D08F,h2
c $D093
@ $D093 label=loc_D093
C $D095,h2
c $D099
@ $D099 label=loc_D099
C $D099,h3
c $D09C
@ $D09C label=cursor
C $D09C,h2
C $D09E,h2
C $D0A0,h3
C $D0A5,h2
c $D0A9
@ $D0A9 label=loc_D0A9
C $D0A9,h2
C $D0AB,h3
C $D0B0,h2
c $D0B4
@ $D0B4 label=loc_D0B4
C $D0B6,h2
c $D0BA
@ $D0BA label=loc_D0BA
C $D0BC,h2
c $D0C0
@ $D0C0 label=loc_D0C0
C $D0C2,6,h2,2,h2
c $D0C8
@ $D0C8 label=keyboard
C $D0C8,16,h5,2,h2,5,h2
C $D0D9,h2
C $D0DB,h3
C $D0E0,h2
c $D0E4
@ $D0E4 label=loc_D0E4
C $D0E6,h2
c $D0EA
@ $D0EA label=loc_D0EA
C $D0EC,h2
c $D0F0
@ $D0F0 label=loc_D0F0
C $D0F2,h2
c $D0F6
@ $D0F6 label=loc_D0F6
C $D0F6,h7
c $D0FF
@ $D0FF label=loc_D0FF
C $D0FF,h7
c $D108
@ $D108 label=loc_D108
C $D108,h7
c $D111
@ $D111 label=finished_input
C $D111,h5
C $D116,h2
C $D11A,9,h5,2,h2
c $D125
@ $D125 label=loc_D125
C $D126,h3
c $D12A
@ $D12A label=lose_life
C $D12A,h6
C $D133,h3
C $D139,h6
C $D140,h3
C $D143,h3
C $D149,h2
C $D14C,h3
C $D14F,h2
C $D152,h3
C $D155,h3
C $D158,h2
C $D15B,h2
C $D15D,h3
b $D161
@ $D161 label=plyr_spr_1_scratchpad
B $D161,8,h8
b $D169
@ $D169 label=start_loc_1
B $D169,4,h4
b $D16D
@ $D16D label=flags12_1
B $D16D,4,h4
b $D171
@ $D171 label=byte_D171
B $D171,16,h8
b $D181
@ $D181 label=plyr_spr_2_scratchpad
B $D181,8,h8
b $D189
@ $D189 label=start_loc_2
B $D189,8,h8
b $D191
@ $D191 label=byte_D191
B $D191,16,h8
b $D1A1
@ $D1A1 label=plyr_spr_init_data
B $D1A1,16,h8
c $D1B1
@ $D1B1 label=init_start_location
C $D1B1,17,h9,2,h6
C $D1C4,h2
C $D1C6,h3
C $D1C9,h2
C $D1CB,h6
C $D1D1,h2
C $D1D4,h5
C $D1DB,h6
b $D1E2
@ $D1E2 label=start_locations
B $D1E2,4,h4
c $D1E6
@ $D1E6 label=build_screen_objects
C $D1E6,h3
C $D1EA,h2
C $D1EC,h3
c $D1EF
@ $D1EF label=loc_D1EF
C $D1EF,h6
C $D1F5,h6
C $D1FC,h12
C $D208,h2
C $D20A,h3
C $D20D,h11
c $D219
@ $D219 label=flag_room_visited
C $D219,h3
C $D220,h2
C $D223,8,h2,4,h2
C $D22B,h2
C $D22D,h6
c $D237
@ $D237 label=transfer_sprite
C $D239,h3
C $D23E,h3
C $D243,h3
C $D248,h3
c $D24C
@ $D24C label=transfer_sprite_and_print
C $D24C,7,h3,1,h3
c $D255
@ $D255 label=display_panel
C $D255,h10
C $D25F,h3
C $D262,h2
C $D264,h12
C $D270,h3
C $D273,h2
C $D275,h9
b $D27E
@ $D27E label=panel_data
B $D27E,24,h4
c $D296
@ $D296 label=print_border
C $D296,h22
C $D2AC,h3
C $D2AF,h2
C $D2B1,h6
C $D2B7,h2
C $D2B9,h6
C $D2BF,h3
C $D2C2,h2
C $D2C4,h6
C $D2CA,h2
C $D2CC,h3
b $D2CF
@ $D2CF label=border_data
B $D2CF,32,h4
c $D2EF
@ $D2EF label=colour_panel
C $D2F0,h3
C $D2F3,h3
C $D2F6,h6
C $D2FC,h3
C $D2FF,h3
C $D302,h2
C $D304,h3
C $D307,h3
C $D30A,h3
c $D30D
@ $D30D label=colour_sun_moon
C $D30D,h3
C $D310,h2
C $D312,h2
C $D314,h2
c $D317
@ $D317 label=loc_D317
C $D317,h3
C $D31A,h3
C $D31D,h3
c $D320
@ $D320 label=adjust_plyr_xyz_for_room_size
C $D320,11,h5,1,h5
C $D32C,h3
C $D330,h2
C $D333,h2
C $D335,h3
C $D339,h2
C $D33C,h2
c $D33F
@ $D33F label=enter_arch_s
C $D33F,h5
C $D344,h2
C $D347,h3
c $D34A
@ $D34A label=adjust_plyr_y
C $D34A,h3
c $D34D
@ $D34D label=copy_spr_1_xy_2
C $D34D,h4
C $D351,h4
C $D355,h3
C $D358,h3
C $D35B,h3
C $D35E,h3
c $D362
@ $D362 label=enter_arch_n
C $D362,h5
C $D368,h2
C $D36A,h3
C $D36D,h2
c $D36F
@ $D36F label=enter_arch_w
C $D36F,h7
C $D377,h3
c $D37A
@ $D37A label=adjust_plyr_x
C $D37A,h5
c $D37F
@ $D37F label=enter_arch_e
C $D37F,h5
C $D385,h2
C $D387,h3
C $D38A,h2
c $D38C
@ $D38C label=adjust_plyr_Z_for_arch
C $D38C,h4
C $D390,h3
C $D393,h2
c $D395
@ $D395 label=loc_D395
C $D395,h3
C $D398,h2
C $D39B,h3
C $D39E,h3
C $D3A2,h2
C $D3A6,h2
c $D3A9
@ $D3A9 label=adj_plyr_Z
C $D3A9,h3
C $D3AC,h3
C $D3AF,h2
C $D3B1,h3
c $D3B5
@ $D3B5 label=get_ptr_object
C $D3B6,h2
C $D3B9,h2
C $D3C0,h3
c $D3C6
@ $D3C6 label=retrieve_screen
C $D3C6,h3
C $D3C9,h6
c $D3CF
@ $D3CF label=find_screen
C $D3D1,h3
C $D3D4,h2
C $D3D7,h3
C $D3DD,h2
C $D3E0,h2
c $D3E2
@ $D3E2 label=zero_end_of_graphic_objs_tbl
C $D3E2,h3
C $D3E9,h2
C $D3EB,h5
c $D3F0
@ $D3F0 label=found_screen
C $D3F3,h2
C $D3F5,h2
C $D3F7,h3
C $D401,h2
C $D406,h3
C $D409,h3
C $D40E,h3
C $D413,h3
C $D417,h3
c $D41E
@ $D41E label=next_bg_obj
C $D420,h2
C $D422,7,h2,3,h2
C $D42A,h3
c $D432
@ $D432 label=next_bg_obj_sprite
C $D432,h3
C $D437,h3
C $D43C,h2
C $D43E,h3
C $D443,h2
C $D447,h5
c $D44C
@ $D44C label=find_fg_objs
c $D452
@ $D452 label=next_fg_obj
C $D453,h2
C $D45F,h2
C $D461,h3
C $D464,h3
c $D46B
@ $D46B label=next_fg_obj_in_count
c $D46C
@ $D46C label=next_fg_obj_sprite
C $D46E,h3
C $D473,h3
C $D478,h3
C $D47D,h3
C $D482,h9
C $D48F,h2
C $D497,h2
C $D49A,h2
C $D49C,h3
C $D4A2,h2
C $D4A7,h2
C $D4AA,h2
C $D4AC,h3
C $D4B2,h2
C $D4BB,h2
C $D4BE,h3
C $D4C2,h3
C $D4C6,h3
C $D4CB,h2
c $D4CD
@ $D4CD label=loc_D4CD
C $D4CD,8,hh4,2,h2
C $D4D8,7,h2,3,h2
C $D4E0,10,h3,5,h2
c $D4EA
@ $D4EA label=loc_D4EA
C $D4EF,h3
c $D4F2
@ $D4F2 label=add_HL_A
C $D4F5,h2
c $D4F9
@ $D4F9 label=HL_equals_DE_x_A
C $D4FA,h5
c $D4FF
@ $D4FF label=loc_D4FF
C $D501,h2
c $D504
@ $D504 label=loc_D504
C $D504,h2
c $D508
@ $D508 label=zero_DE
c $D509
@ $D509 label=fill_DE
C $D50B,h2
c $D50E
@ $D50E label=handle_pause
C $D50E,h2
C $D510,h3
C $D516,h2
c $D519
@ $D519 label=debounce_space_press
C $D519,h5
C $D520,h5
c $D525
@ $D525 label=wait_for_space
C $D525,h5
C $D52C,h2
c $D52E
@ $D52E label=debounce_space_release
C $D52E,h5
C $D535,h5
c $D53A
@ $D53A label=clr_mem
C $D53A,h2
c $D53C
@ $D53C label=clr_byte
C $D541,h2
c $D544
@ $D544 label=clr_bitmap_memory
C $D544,h3
C $D547,h3
C $D54A,h2
c $D54C
@ $D54C label=clr_attribute_memory
C $D54C,h3
C $D54F,h3
C $D552,h2
C $D554,h2
c $D556
@ $D556 label=fill_attr
C $D556,h3
C $D559,h3
C $D55D,h2
c $D55F
@ $D55F label=clear_scrn
C $D560,h2
C $D562,h5
c $D567
@ $D567 label=clear_scrn_buffer
C $D567,h3
C $D56A,h5
c $D56F
@ $D56F label=update_screen
C $D56F,h3
C $D572,h3
C $D575,h3
c $D578
@ $D578 label=loc_D578
c $D57B
@ $D57B label=loc_D57B
C $D57D,h2
C $D581,h2
C $D584,h3
C $D58C,13,h4,1,h2,1,h2,1,h2
c $D59A
@ $D59A label=loc_D59A
C $D59C,h2
c $D59F
@ $D59F label=render_dynamic_objects
C $D5A0,8,h3,2,h3
C $D5A9,h6
C $D5AF,h3
c $D5B2
@ $D5B2 label=wipe_next_object
C $D5B2,h3
C $D5B7,h3
C $D5BA,h2
C $D5BC,h6
C $D5C5,h4
C $D5C9,h2
C $D5CB,h4
C $D5CF,h3
C $D5D2,h3
C $D5D5,h3
C $D5D8,h3
c $D5DB
@ $D5DB label=loc_D5DB
C $D5DB,h3
C $D5E1,h2
C $D5E3,h3
C $D5E7,h3
C $D5ED,h2
C $D5EF,h3
C $D5F3,h2
c $D5F6
@ $D5F6 label=loc_D5F6
C $D5FA,h2
C $D600,h3
C $D603,h3
C $D606,h2
C $D608,h3
c $D60B
@ $D60B label=loc_D60B
C $D60B,h3
C $D60E,h3
C $D612,h3
C $D615,h3
C $D619,h2
c $D61C
@ $D61C label=loc_D61C
C $D61F,h2
C $D621,7,h2,1,h4
c $D62C
@ $D62C label=loc_D62C
C $D62C,h3
C $D62F,h3
C $D638,7,h3,1,h3
C $D643,h6
c $D649
@ $D649 label=loc_D649
C $D649,h5
c $D64E
@ $D64E label=loc_D64E
C $D64E,h5
c $D653
@ $D653 label=loc_D653
C $D653,h15
C $D663,h3
c $D666
@ $D666 label=loc_D666
C $D666,h3
C $D66B,h2
C $D674,h3
C $D677,h2
c $D679
@ $D679 label=loc_D679
c $D67C
@ $D67C label=blit_to_screen
C $D67F,8,h2,3,h3
C $D68C,13,h4,1,h2,1,h2,1,h2
c $D69A
@ $D69A label=loc_D69A
C $D69B,h2
c $D69E
@ $D69E label=build_lookup_tbls
C $D69E,h2
c $D6A0
@ $D6A0 label=loc_D6A0
C $D6A0,7,h2,1,h4
c $D6A7
@ $D6A7 label=loc_D6A7
C $D6B3,5,h2,1,h2
C $D6B8,h3
c $D6BB
@ $D6BB label=loc_D6BB
C $D6BC,h2
c $D6BE
@ $D6BE label=loc_D6BE
C $D6C2,h2
C $D6C6,h2
c $D6C9
@ $D6C9 label=calc_pixel_XY
C $D6C9,h3
C $D6CC,h3
C $D6CF,h2
C $D6D1,h3
C $D6D4,h3
C $D6D7,h3
C $D6DA,h3
C $D6DD,h2
C $D6E1,h3
C $D6E4,h2
C $D6E6,h3
C $D6E9,h3
C $D6EC,h2
c $D6EF
@ $D6EF label=flip_sprite
C $D6EF,h3
C $D6F2,h2
C $D6F5,h3
C $D6FE,h3
c $D704
@ $D704 label=calc_pixel_XY_and_render
C $D704,h3
C $D707,h2
C $D709,h2
C $D70B,hh4
c $D710
@ $D710 label=loc_D710
C $D710,h7
c $D718
@ $D718 label=print_sprite
C $D718,h3
C $D71B,h3
C $D71E,h2
C $D720,12,h2,1,h4,3,h2
C $D72E,h3
C $D732,10,h2,6,h2
c $D73C
@ $D73C label=loc_D73C
C $D73C,10,h3,2,h5
C $D748,h3
C $D74B,h3
C $D74E,h2
C $D750,h2
C $D754,h3
C $D757,h3
c $D75A
@ $D75A label=loc_D75A
C $D75A,h3
C $D75D,h3
C $D760,h7
C $D76A,h3
C $D76D,h2
c $D76F
@ $D76F label=loc_D76F
C $D771,h2
C $D773,h3
C $D77C,h4
c $D790
@ $D790 label=loc_D790
C $D7A7,h3
c $D7AA
@ $D7AA label=loc_D7AA
c $D7AC
@ $D7AC label=loc_D7AC
C $D7AC,h2
c $D7FF
@ $D7FF label=loc_D7FF
c $D800
@ $D800 label=loc_D800
C $D800,16,h2,2,h2,3,h7
c $D811
@ $D811 label=calc_vidbuf_addr
C $D81E,h3
c $D826
@ $D826 label=calc_vram_addr
C $D82A,28,h2,3,h2,5,h2,7,h2,3,h2
c $D848
@ $D848 label=calc_attrib_addr
C $D85E,h3
c $D865
@ $D865 label=vflip_sprite_data
C $D867,h3
C $D86A,h2
C $D86C,h2
C $D86F,h2
C $D873,h2
C $D87C,h2
C $D87E,h3
C $D885,h3
c $D88C
@ $D88C label=loc_D88C
c $D88D
@ $D88D label=vflip_sprite_line_pair
C $D894,7,h2,2,h3
C $D89C,h3
C $D8A0,h2
c $D8A2
@ $D8A2 label=loc_D8A2
C $D8A5,h3
C $D8A8,h2
C $D8AA,h2
C $D8AD,h2
C $D8B0,h2
C $D8BC,h2
c $D8BF
@ $D8BF label=loc_D8BF
C $D8CA,h2
c $D8CD
@ $D8CD label=loc_D8CD
C $D8D2,10,h2,2,h2,2,h2
c $D8DC
@ $D8DC label=loc_D8DC
b $D8DE
@ $D8DE label=aCopyright1984A_c_g_
T $D8DE,21,21
# Screen buffer. The drawing code composes a room here, and the copy to display reads it back.
b $D8F3
b $F0F3
# Built at run time: shifted-sprite and bit-reversed-byte lookups.
b $F100
