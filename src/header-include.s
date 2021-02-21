
// .nolist

.set	sys_read,	63
.equ	sys_write,	64
.equ  sys_exit, 93

.equ	stdout, 1
.equ	stdin,  1

.set	BIT_PER_WORD,	0x040   // 020H for 32 Bit, 040H for 64 Bit
.set	BYTE_PER_WORD,	0x08    // 004H for 32 Bit, 008H for 64 Bit
//
// Variable size and Exponent size must be multiple of 4 byte (32 bit) DWord
//
//--------------------------------------------------------------------
.set	VAR_WSIZE,	0x040	// Size of variable in words
//--------------------------------------------------------------------
.set	VAR_BSIZE,	(VAR_WSIZE * BYTE_PER_WORD)	// Maximum size of variable in bytes
.set	INT_WSIZE, 	1
.set	INT_BSIZE,	(INT_WSIZE * BYTE_PER_WORD)
.set	FCT_WSIZE, 	(VAR_WSIZE - INT_WSIZE)
.set	FCT_BSIZE,	(FCT_WSIZE * BYTE_PER_WORD)

.set	VAR_MSB_OFST,	VAR_BSIZE-1			// Offset mantissa most significant byte
.set	VAR_MSW_OFST,	VAR_BSIZE-(BYTE_PER_WORD)	// Offset mantissa most significant word

.set	GUARDWORDS,	4
.set	GUARDBYTES,	(GUARDWORDS*BYTE_PER_WORD)

.set	INIT_NO_WORD,	4+GUARDWORDS                    // Initial accuracy setting when program starts
.set	MINIMUM_WORD,	2+GUARDWORDS			//**** Includes GUARD Bytes ****

.set	INIT_SIG_DIG,	60
.set	INIT_EXT_DIG,	0
.set	MINIMUM_DIG,	5				// needed for printing



/*-------------------------
Variable Handle Numbers
-------------------------*/

.set	HAND_ACC,	0
.set	HAND_OPR,	1
.set	HAND_WORKA,	2
.set	HAND_WORKB,	3
.set	HAND_WORKC,	4
.set	HAND_XREG,	5
.set	HAND_YREG,	6
.set	HAND_ZREG,	7
.set	HAND_TREG,	8
.set	HAND_REG0,	9
.set	HAND_REG1,	10
.set	HAND_REG2,	11
.set	HAND_REG3,	12

/*	.set	HAND_REG4,	13
.set	HAND_REG5,	14
.set	HAND_REG6,	15
.set	HAND_REG7,	16
*/
.set	TOPHAND,	HAND_REG3

// .list
