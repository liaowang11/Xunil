
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 6c 39 11 f0       	mov    $0xf011396c,%eax
f010004b:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 33 11 f0 	movl   $0xf0113300,(%esp)
f0100063:	e8 be 15 00 00       	call   f0101626 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8f 04 00 00       	call   f01004fc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 1b 10 f0 	movl   $0xf0101b20,(%esp)
f010007c:	e8 2d 0a 00 00       	call   f0100aae <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 75 08 00 00       	call   f01008fb <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 7e 06 00 00       	call   f0100710 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 33 11 f0 00 	cmpl   $0x0,0xf0113300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 33 11 f0    	mov    %esi,0xf0113300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 3b 1b 10 f0 	movl   $0xf0101b3b,(%esp)
f01000c8:	e8 e1 09 00 00       	call   f0100aae <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 a2 09 00 00       	call   f0100a7b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 77 1b 10 f0 	movl   $0xf0101b77,(%esp)
f01000e0:	e8 c9 09 00 00       	call   f0100aae <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 1f 06 00 00       	call   f0100710 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 53 1b 10 f0 	movl   $0xf0101b53,(%esp)
f0100112:	e8 97 09 00 00       	call   f0100aae <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 55 09 00 00       	call   f0100a7b <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 77 1b 10 f0 	movl   $0xf0101b77,(%esp)
f010012d:	e8 7c 09 00 00       	call   f0100aae <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 44 35 11 f0    	mov    0xf0113544,%edx
f010017f:	88 82 40 33 11 f0    	mov    %al,-0xfeeccc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 35 11 f0       	mov    %eax,0xf0113544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 c7                	mov    %eax,%edi
f01001b2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b7:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001b8:	a8 20                	test   $0x20,%al
f01001ba:	75 1b                	jne    f01001d7 <cons_putc+0x30>
f01001bc:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c1:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c6:	e8 75 ff ff ff       	call   f0100140 <delay>
f01001cb:	89 f2                	mov    %esi,%edx
f01001cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001ce:	a8 20                	test   $0x20,%al
f01001d0:	75 05                	jne    f01001d7 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d2:	83 eb 01             	sub    $0x1,%ebx
f01001d5:	75 ef                	jne    f01001c6 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001d7:	89 fa                	mov    %edi,%edx
f01001d9:	89 f8                	mov    %edi,%eax
f01001db:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001de:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e4:	b2 79                	mov    $0x79,%dl
f01001e6:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e7:	84 c0                	test   %al,%al
f01001e9:	78 1b                	js     f0100206 <cons_putc+0x5f>
f01001eb:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f0:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f5:	e8 46 ff ff ff       	call   f0100140 <delay>
f01001fa:	89 f2                	mov    %esi,%edx
f01001fc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fd:	84 c0                	test   %al,%al
f01001ff:	78 05                	js     f0100206 <cons_putc+0x5f>
f0100201:	83 eb 01             	sub    $0x1,%ebx
f0100204:	75 ef                	jne    f01001f5 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100206:	ba 78 03 00 00       	mov    $0x378,%edx
f010020b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010020f:	ee                   	out    %al,(%dx)
f0100210:	b2 7a                	mov    $0x7a,%dl
f0100212:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100217:	ee                   	out    %al,(%dx)
f0100218:	b8 08 00 00 00       	mov    $0x8,%eax
f010021d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010021e:	89 fa                	mov    %edi,%edx
f0100220:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100226:	89 f8                	mov    %edi,%eax
f0100228:	80 cc 07             	or     $0x7,%ah
f010022b:	85 d2                	test   %edx,%edx
f010022d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100230:	89 f8                	mov    %edi,%eax
f0100232:	25 ff 00 00 00       	and    $0xff,%eax
f0100237:	83 f8 09             	cmp    $0x9,%eax
f010023a:	74 7c                	je     f01002b8 <cons_putc+0x111>
f010023c:	83 f8 09             	cmp    $0x9,%eax
f010023f:	7f 0b                	jg     f010024c <cons_putc+0xa5>
f0100241:	83 f8 08             	cmp    $0x8,%eax
f0100244:	0f 85 a2 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010024a:	eb 16                	jmp    f0100262 <cons_putc+0xbb>
f010024c:	83 f8 0a             	cmp    $0xa,%eax
f010024f:	90                   	nop
f0100250:	74 40                	je     f0100292 <cons_putc+0xeb>
f0100252:	83 f8 0d             	cmp    $0xd,%eax
f0100255:	0f 85 91 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010025b:	90                   	nop
f010025c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100260:	eb 38                	jmp    f010029a <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e4 00 00 00    	je     f0100356 <cons_putc+0x1af>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100283:	83 cf 20             	or     $0x20,%edi
f0100286:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
f010028c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100290:	eb 77                	jmp    f0100309 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100292:	66 83 05 54 35 11 f0 	addw   $0x50,0xf0113554
f0100299:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029a:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002a1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a7:	c1 e8 16             	shr    $0x16,%eax
f01002aa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ad:	c1 e0 04             	shl    $0x4,%eax
f01002b0:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
f01002b6:	eb 51                	jmp    f0100309 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f01002b8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002bd:	e8 e5 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c7:	e8 db fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d1:	e8 d1 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002db:	e8 c7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e5:	e8 bd fe ff ff       	call   f01001a7 <cons_putc>
f01002ea:	eb 1d                	jmp    f0100309 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ec:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002f3:	0f b7 c8             	movzwl %ax,%ecx
f01002f6:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
f01002fc:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100300:	83 c0 01             	add    $0x1,%eax
f0100303:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100309:	66 81 3d 54 35 11 f0 	cmpw   $0x7cf,0xf0113554
f0100310:	cf 07 
f0100312:	76 42                	jbe    f0100356 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100314:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0100319:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100320:	00 
f0100321:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100327:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032b:	89 04 24             	mov    %eax,(%esp)
f010032e:	e8 4e 13 00 00       	call   f0101681 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100333:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100339:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100344:	83 c0 01             	add    $0x1,%eax
f0100347:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034c:	75 f0                	jne    f010033e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034e:	66 83 2d 54 35 11 f0 	subw   $0x50,0xf0113554
f0100355:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100356:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f010035c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100361:	89 ca                	mov    %ecx,%edx
f0100363:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100364:	0f b7 35 54 35 11 f0 	movzwl 0xf0113554,%esi
f010036b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036e:	89 f0                	mov    %esi,%eax
f0100370:	66 c1 e8 08          	shr    $0x8,%ax
f0100374:	89 da                	mov    %ebx,%edx
f0100376:	ee                   	out    %al,(%dx)
f0100377:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037c:	89 ca                	mov    %ecx,%edx
f010037e:	ee                   	out    %al,(%dx)
f010037f:	89 f0                	mov    %esi,%eax
f0100381:	89 da                	mov    %ebx,%edx
f0100383:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100384:	83 c4 2c             	add    $0x2c,%esp
f0100387:	5b                   	pop    %ebx
f0100388:	5e                   	pop    %esi
f0100389:	5f                   	pop    %edi
f010038a:	5d                   	pop    %ebp
f010038b:	c3                   	ret    

f010038c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038c:	55                   	push   %ebp
f010038d:	89 e5                	mov    %esp,%ebp
f010038f:	53                   	push   %ebx
f0100390:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100393:	ba 64 00 00 00       	mov    $0x64,%edx
f0100398:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100399:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039e:	a8 01                	test   $0x1,%al
f01003a0:	0f 84 de 00 00 00    	je     f0100484 <kbd_proc_data+0xf8>
f01003a6:	b2 60                	mov    $0x60,%dl
f01003a8:	ec                   	in     (%dx),%al
f01003a9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003ab:	3c e0                	cmp    $0xe0,%al
f01003ad:	75 11                	jne    f01003c0 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003af:	83 0d 48 35 11 f0 40 	orl    $0x40,0xf0113548
		return 0;
f01003b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003bb:	e9 c4 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003c0:	84 c0                	test   %al,%al
f01003c2:	79 37                	jns    f01003fb <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c4:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f01003ca:	89 cb                	mov    %ecx,%ebx
f01003cc:	83 e3 40             	and    $0x40,%ebx
f01003cf:	83 e0 7f             	and    $0x7f,%eax
f01003d2:	85 db                	test   %ebx,%ebx
f01003d4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d7:	0f b6 d2             	movzbl %dl,%edx
f01003da:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f01003e1:	83 c8 40             	or     $0x40,%eax
f01003e4:	0f b6 c0             	movzbl %al,%eax
f01003e7:	f7 d0                	not    %eax
f01003e9:	21 c1                	and    %eax,%ecx
f01003eb:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 89 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fb:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f0100401:	f6 c1 40             	test   $0x40,%cl
f0100404:	74 0e                	je     f0100414 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100406:	89 c2                	mov    %eax,%edx
f0100408:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040e:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
	}

	shift |= shiftcode[data];
f0100414:	0f b6 d2             	movzbl %dl,%edx
f0100417:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f010041e:	0b 05 48 35 11 f0    	or     0xf0113548,%eax
	shift ^= togglecode[data];
f0100424:	0f b6 8a a0 1c 10 f0 	movzbl -0xfefe360(%edx),%ecx
f010042b:	31 c8                	xor    %ecx,%eax
f010042d:	a3 48 35 11 f0       	mov    %eax,0xf0113548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100432:	89 c1                	mov    %eax,%ecx
f0100434:	83 e1 03             	and    $0x3,%ecx
f0100437:	8b 0c 8d a0 1d 10 f0 	mov    -0xfefe260(,%ecx,4),%ecx
f010043e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100442:	a8 08                	test   $0x8,%al
f0100444:	74 19                	je     f010045f <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100446:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100449:	83 fa 19             	cmp    $0x19,%edx
f010044c:	77 05                	ja     f0100453 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044e:	83 eb 20             	sub    $0x20,%ebx
f0100451:	eb 0c                	jmp    f010045f <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100453:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100456:	8d 53 20             	lea    0x20(%ebx),%edx
f0100459:	83 f9 19             	cmp    $0x19,%ecx
f010045c:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045f:	f7 d0                	not    %eax
f0100461:	a8 06                	test   $0x6,%al
f0100463:	75 1f                	jne    f0100484 <kbd_proc_data+0xf8>
f0100465:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046b:	75 17                	jne    f0100484 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010046d:	c7 04 24 6d 1b 10 f0 	movl   $0xf0101b6d,(%esp)
f0100474:	e8 35 06 00 00       	call   f0100aae <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100479:	ba 92 00 00 00       	mov    $0x92,%edx
f010047e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100483:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100484:	89 d8                	mov    %ebx,%eax
f0100486:	83 c4 14             	add    $0x14,%esp
f0100489:	5b                   	pop    %ebx
f010048a:	5d                   	pop    %ebp
f010048b:	c3                   	ret    

f010048c <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048c:	55                   	push   %ebp
f010048d:	89 e5                	mov    %esp,%ebp
f010048f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100492:	83 3d 20 33 11 f0 00 	cmpl   $0x0,0xf0113320
f0100499:	74 0a                	je     f01004a5 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010049b:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a0:	e8 c5 fc ff ff       	call   f010016a <cons_intr>
}
f01004a5:	c9                   	leave  
f01004a6:	c3                   	ret    

f01004a7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a7:	55                   	push   %ebp
f01004a8:	89 e5                	mov    %esp,%ebp
f01004aa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ad:	b8 8c 03 10 f0       	mov    $0xf010038c,%eax
f01004b2:	e8 b3 fc ff ff       	call   f010016a <cons_intr>
}
f01004b7:	c9                   	leave  
f01004b8:	c3                   	ret    

f01004b9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b9:	55                   	push   %ebp
f01004ba:	89 e5                	mov    %esp,%ebp
f01004bc:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bf:	e8 c8 ff ff ff       	call   f010048c <serial_intr>
	kbd_intr();
f01004c4:	e8 de ff ff ff       	call   f01004a7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c9:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004cf:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d4:	3b 15 44 35 11 f0    	cmp    0xf0113544,%edx
f01004da:	74 1e                	je     f01004fa <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004dc:	0f b6 82 40 33 11 f0 	movzbl -0xfeeccc0(%edx),%eax
f01004e3:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ec:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f1:	0f 44 d1             	cmove  %ecx,%edx
f01004f4:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
		return c;
	}
	return 0;
}
f01004fa:	c9                   	leave  
f01004fb:	c3                   	ret    

f01004fc <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	57                   	push   %edi
f0100500:	56                   	push   %esi
f0100501:	53                   	push   %ebx
f0100502:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100505:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100513:	5a a5 
	if (*cp != 0xA55A) {
f0100515:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100520:	74 11                	je     f0100533 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100522:	c7 05 4c 35 11 f0 b4 	movl   $0x3b4,0xf011354c
f0100529:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100531:	eb 16                	jmp    f0100549 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100533:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053a:	c7 05 4c 35 11 f0 d4 	movl   $0x3d4,0xf011354c
f0100541:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100544:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100549:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f010054f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100554:	89 ca                	mov    %ecx,%edx
f0100556:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100557:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055a:	89 da                	mov    %ebx,%edx
f010055c:	ec                   	in     (%dx),%al
f010055d:	0f b6 f8             	movzbl %al,%edi
f0100560:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100563:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100568:	89 ca                	mov    %ecx,%edx
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056e:	89 35 50 35 11 f0    	mov    %esi,0xf0113550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100574:	0f b6 d8             	movzbl %al,%ebx
f0100577:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100579:	66 89 3d 54 35 11 f0 	mov    %di,0xf0113554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100580:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100585:	b8 00 00 00 00       	mov    $0x0,%eax
f010058a:	89 da                	mov    %ebx,%edx
f010058c:	ee                   	out    %al,(%dx)
f010058d:	b2 fb                	mov    $0xfb,%dl
f010058f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100594:	ee                   	out    %al,(%dx)
f0100595:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010059a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	b2 f9                	mov    $0xf9,%dl
f01005a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	b2 fb                	mov    $0xfb,%dl
f01005ac:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b2 fc                	mov    $0xfc,%dl
f01005b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	b2 f9                	mov    $0xf9,%dl
f01005bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	b2 fd                	mov    $0xfd,%dl
f01005c4:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c5:	3c ff                	cmp    $0xff,%al
f01005c7:	0f 95 c0             	setne  %al
f01005ca:	0f b6 c0             	movzbl %al,%eax
f01005cd:	89 c6                	mov    %eax,%esi
f01005cf:	a3 20 33 11 f0       	mov    %eax,0xf0113320
f01005d4:	89 da                	mov    %ebx,%edx
f01005d6:	ec                   	in     (%dx),%al
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005da:	85 f6                	test   %esi,%esi
f01005dc:	75 0c                	jne    f01005ea <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f01005de:	c7 04 24 79 1b 10 f0 	movl   $0xf0101b79,(%esp)
f01005e5:	e8 c4 04 00 00       	call   f0100aae <cprintf>
}
f01005ea:	83 c4 1c             	add    $0x1c,%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 a7 fb ff ff       	call   f01001a7 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 ac fe ff ff       	call   f01004b9 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    
f010061d:	00 00                	add    %al,(%eax)
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 b0 1d 10 f0 	movl   $0xf0101db0,(%esp)
f010062d:	e8 7c 04 00 00       	call   f0100aae <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 68 1e 10 f0 	movl   $0xf0101e68,(%esp)
f0100649:	e8 60 04 00 00       	call   f0100aae <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 05 1b 10 	movl   $0x101b05,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 05 1b 10 	movl   $0xf0101b05,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 8c 1e 10 f0 	movl   $0xf0101e8c,(%esp)
f0100665:	e8 44 04 00 00       	call   f0100aae <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 00 33 11 	movl   $0x113300,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 00 33 11 	movl   $0xf0113300,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 b0 1e 10 f0 	movl   $0xf0101eb0,(%esp)
f0100681:	e8 28 04 00 00       	call   f0100aae <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 6c 39 11 	movl   $0x11396c,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 6c 39 11 	movl   $0xf011396c,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 d4 1e 10 f0 	movl   $0xf0101ed4,(%esp)
f010069d:	e8 0c 04 00 00       	call   f0100aae <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 6b 3d 11 f0       	mov    $0xf0113d6b,%eax
f01006a7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ac:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006b2:	85 c0                	test   %eax,%eax
f01006b4:	0f 48 c2             	cmovs  %edx,%eax
f01006b7:	c1 f8 0a             	sar    $0xa,%eax
f01006ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006be:	c7 04 24 f8 1e 10 f0 	movl   $0xf0101ef8,(%esp)
f01006c5:	e8 e4 03 00 00       	call   f0100aae <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cf:	c9                   	leave  
f01006d0:	c3                   	ret    

f01006d1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006d1:	55                   	push   %ebp
f01006d2:	89 e5                	mov    %esp,%ebp
f01006d4:	53                   	push   %ebx
f01006d5:	83 ec 14             	sub    $0x14,%esp
f01006d8:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006dd:	8b 83 e4 1f 10 f0    	mov    -0xfefe01c(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 e0 1f 10 f0    	mov    -0xfefe020(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 c9 1d 10 f0 	movl   $0xf0101dc9,(%esp)
f01006f8:	e8 b1 03 00 00       	call   f0100aae <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 24             	cmp    $0x24,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	57                   	push   %edi
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100719:	c7 04 24 24 1f 10 f0 	movl   $0xf0101f24,(%esp)
f0100720:	e8 89 03 00 00       	call   f0100aae <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100725:	c7 04 24 48 1f 10 f0 	movl   $0xf0101f48,(%esp)
f010072c:	e8 7d 03 00 00       	call   f0100aae <cprintf>


	while (1) {
		buf = readline("K> ");
f0100731:	c7 04 24 d2 1d 10 f0 	movl   $0xf0101dd2,(%esp)
f0100738:	e8 63 0c 00 00       	call   f01013a0 <readline>
f010073d:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010073f:	85 c0                	test   %eax,%eax
f0100741:	74 ee                	je     f0100731 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100743:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010074a:	be 00 00 00 00       	mov    $0x0,%esi
f010074f:	eb 06                	jmp    f0100757 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100751:	c6 03 00             	movb   $0x0,(%ebx)
f0100754:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100757:	0f b6 03             	movzbl (%ebx),%eax
f010075a:	84 c0                	test   %al,%al
f010075c:	74 6d                	je     f01007cb <monitor+0xbb>
f010075e:	0f be c0             	movsbl %al,%eax
f0100761:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100765:	c7 04 24 d6 1d 10 f0 	movl   $0xf0101dd6,(%esp)
f010076c:	e8 5a 0e 00 00       	call   f01015cb <strchr>
f0100771:	85 c0                	test   %eax,%eax
f0100773:	75 dc                	jne    f0100751 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100775:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100778:	74 51                	je     f01007cb <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010077a:	83 fe 0f             	cmp    $0xf,%esi
f010077d:	8d 76 00             	lea    0x0(%esi),%esi
f0100780:	75 16                	jne    f0100798 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100782:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100789:	00 
f010078a:	c7 04 24 db 1d 10 f0 	movl   $0xf0101ddb,(%esp)
f0100791:	e8 18 03 00 00       	call   f0100aae <cprintf>
f0100796:	eb 99                	jmp    f0100731 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100798:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010079c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010079f:	0f b6 03             	movzbl (%ebx),%eax
f01007a2:	84 c0                	test   %al,%al
f01007a4:	75 0c                	jne    f01007b2 <monitor+0xa2>
f01007a6:	eb af                	jmp    f0100757 <monitor+0x47>
			buf++;
f01007a8:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007ab:	0f b6 03             	movzbl (%ebx),%eax
f01007ae:	84 c0                	test   %al,%al
f01007b0:	74 a5                	je     f0100757 <monitor+0x47>
f01007b2:	0f be c0             	movsbl %al,%eax
f01007b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b9:	c7 04 24 d6 1d 10 f0 	movl   $0xf0101dd6,(%esp)
f01007c0:	e8 06 0e 00 00       	call   f01015cb <strchr>
f01007c5:	85 c0                	test   %eax,%eax
f01007c7:	74 df                	je     f01007a8 <monitor+0x98>
f01007c9:	eb 8c                	jmp    f0100757 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01007cb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007d2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007d3:	85 f6                	test   %esi,%esi
f01007d5:	0f 84 56 ff ff ff    	je     f0100731 <monitor+0x21>
f01007db:	bb e0 1f 10 f0       	mov    $0xf0101fe0,%ebx
f01007e0:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e5:	8b 03                	mov    (%ebx),%eax
f01007e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007eb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01007ee:	89 04 24             	mov    %eax,(%esp)
f01007f1:	e8 5a 0d 00 00       	call   f0101550 <strcmp>
f01007f6:	85 c0                	test   %eax,%eax
f01007f8:	75 24                	jne    f010081e <monitor+0x10e>
			return commands[i].func(argc, argv, tf);
f01007fa:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01007fd:	8b 55 08             	mov    0x8(%ebp),%edx
f0100800:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100804:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100807:	89 54 24 04          	mov    %edx,0x4(%esp)
f010080b:	89 34 24             	mov    %esi,(%esp)
f010080e:	ff 14 85 e8 1f 10 f0 	call   *-0xfefe018(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100815:	85 c0                	test   %eax,%eax
f0100817:	78 28                	js     f0100841 <monitor+0x131>
f0100819:	e9 13 ff ff ff       	jmp    f0100731 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010081e:	83 c7 01             	add    $0x1,%edi
f0100821:	83 c3 0c             	add    $0xc,%ebx
f0100824:	83 ff 03             	cmp    $0x3,%edi
f0100827:	75 bc                	jne    f01007e5 <monitor+0xd5>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100829:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010082c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100830:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f0100837:	e8 72 02 00 00       	call   f0100aae <cprintf>
f010083c:	e9 f0 fe ff ff       	jmp    f0100731 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100841:	83 c4 5c             	add    $0x5c,%esp
f0100844:	5b                   	pop    %ebx
f0100845:	5e                   	pop    %esi
f0100846:	5f                   	pop    %edi
f0100847:	5d                   	pop    %ebp
f0100848:	c3                   	ret    

f0100849 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100849:	55                   	push   %ebp
f010084a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010084c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010084f:	5d                   	pop    %ebp
f0100850:	c3                   	ret    

f0100851 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100851:	55                   	push   %ebp
f0100852:	89 e5                	mov    %esp,%ebp
f0100854:	57                   	push   %edi
f0100855:	56                   	push   %esi
f0100856:	53                   	push   %ebx
f0100857:	83 ec 3c             	sub    $0x3c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010085a:	89 eb                	mov    %ebp,%ebx
f010085c:	89 de                	mov    %ebx,%esi
        uint32_t ebp = read_ebp();
        uint32_t eip = read_eip();
f010085e:	e8 e6 ff ff ff       	call   f0100849 <read_eip>
f0100863:	89 c7                	mov    %eax,%edi
        uint32_t new_eip,new_ebp;
        cprintf("Stack backtrace:\n");
f0100865:	c7 04 24 0e 1e 10 f0 	movl   $0xf0101e0e,(%esp)
f010086c:	e8 3d 02 00 00       	call   f0100aae <cprintf>
        while(ebp != 0){
f0100871:	85 db                	test   %ebx,%ebx
f0100873:	74 4e                	je     f01008c3 <mon_backtrace+0x72>
          cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, *((uint32_t*)ebp+2), *((uint32_t*)ebp+3), *((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6), *((uint32_t*)ebp+7), *((uint32_t*)ebp+8));
f0100875:	8b 46 20             	mov    0x20(%esi),%eax
f0100878:	89 44 24 24          	mov    %eax,0x24(%esp)
f010087c:	8b 46 1c             	mov    0x1c(%esi),%eax
f010087f:	89 44 24 20          	mov    %eax,0x20(%esp)
f0100883:	8b 46 18             	mov    0x18(%esi),%eax
f0100886:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f010088a:	8b 46 14             	mov    0x14(%esi),%eax
f010088d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100891:	8b 46 10             	mov    0x10(%esi),%eax
f0100894:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100898:	8b 46 0c             	mov    0xc(%esi),%eax
f010089b:	89 44 24 10          	mov    %eax,0x10(%esp)
f010089f:	8b 46 08             	mov    0x8(%esi),%eax
f01008a2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008a6:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01008aa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01008ae:	c7 04 24 70 1f 10 f0 	movl   $0xf0101f70,(%esp)
f01008b5:	e8 f4 01 00 00       	call   f0100aae <cprintf>
          ebp = *((uint32_t *)ebp);
f01008ba:	8b 36                	mov    (%esi),%esi
          eip = *((uint32_t *)ebp + 1);
f01008bc:	8b 7e 04             	mov    0x4(%esi),%edi
{
        uint32_t ebp = read_ebp();
        uint32_t eip = read_eip();
        uint32_t new_eip,new_ebp;
        cprintf("Stack backtrace:\n");
        while(ebp != 0){
f01008bf:	85 f6                	test   %esi,%esi
f01008c1:	75 b2                	jne    f0100875 <mon_backtrace+0x24>
          cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, *((uint32_t*)ebp+2), *((uint32_t*)ebp+3), *((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6), *((uint32_t*)ebp+7), *((uint32_t*)ebp+8));
          ebp = *((uint32_t *)ebp);
          eip = *((uint32_t *)ebp + 1);
        }
	return 0;
}
f01008c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c8:	83 c4 3c             	add    $0x3c,%esp
f01008cb:	5b                   	pop    %ebx
f01008cc:	5e                   	pop    %esi
f01008cd:	5f                   	pop    %edi
f01008ce:	5d                   	pop    %ebp
f01008cf:	c3                   	ret    

f01008d0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008d0:	55                   	push   %ebp
f01008d1:	89 e5                	mov    %esp,%ebp
f01008d3:	56                   	push   %esi
f01008d4:	53                   	push   %ebx
f01008d5:	83 ec 10             	sub    $0x10,%esp
f01008d8:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008da:	89 04 24             	mov    %eax,(%esp)
f01008dd:	e8 5e 01 00 00       	call   f0100a40 <mc146818_read>
f01008e2:	89 c6                	mov    %eax,%esi
f01008e4:	83 c3 01             	add    $0x1,%ebx
f01008e7:	89 1c 24             	mov    %ebx,(%esp)
f01008ea:	e8 51 01 00 00       	call   f0100a40 <mc146818_read>
f01008ef:	c1 e0 08             	shl    $0x8,%eax
f01008f2:	09 f0                	or     %esi,%eax
}
f01008f4:	83 c4 10             	add    $0x10,%esp
f01008f7:	5b                   	pop    %ebx
f01008f8:	5e                   	pop    %esi
f01008f9:	5d                   	pop    %ebp
f01008fa:	c3                   	ret    

f01008fb <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
f01008fe:	83 ec 18             	sub    $0x18,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100901:	b8 15 00 00 00       	mov    $0x15,%eax
f0100906:	e8 c5 ff ff ff       	call   f01008d0 <nvram_read>
f010090b:	c1 e0 0a             	shl    $0xa,%eax
f010090e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100914:	85 c0                	test   %eax,%eax
f0100916:	0f 48 c2             	cmovs  %edx,%eax
f0100919:	c1 f8 0c             	sar    $0xc,%eax
f010091c:	a3 58 35 11 f0       	mov    %eax,0xf0113558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100921:	b8 17 00 00 00       	mov    $0x17,%eax
f0100926:	e8 a5 ff ff ff       	call   f01008d0 <nvram_read>
f010092b:	c1 e0 0a             	shl    $0xa,%eax
f010092e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100934:	85 c0                	test   %eax,%eax
f0100936:	0f 48 c2             	cmovs  %edx,%eax
f0100939:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010093c:	85 c0                	test   %eax,%eax
f010093e:	74 0e                	je     f010094e <mem_init+0x53>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100940:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100946:	89 15 60 39 11 f0    	mov    %edx,0xf0113960
f010094c:	eb 0c                	jmp    f010095a <mem_init+0x5f>
	else
		npages = npages_basemem;
f010094e:	8b 15 58 35 11 f0    	mov    0xf0113558,%edx
f0100954:	89 15 60 39 11 f0    	mov    %edx,0xf0113960

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010095a:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010095d:	c1 e8 0a             	shr    $0xa,%eax
f0100960:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100964:	a1 58 35 11 f0       	mov    0xf0113558,%eax
f0100969:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010096c:	c1 e8 0a             	shr    $0xa,%eax
f010096f:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100973:	a1 60 39 11 f0       	mov    0xf0113960,%eax
f0100978:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010097b:	c1 e8 0a             	shr    $0xa,%eax
f010097e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100982:	c7 04 24 04 20 10 f0 	movl   $0xf0102004,(%esp)
f0100989:	e8 20 01 00 00       	call   f0100aae <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f010098e:	c7 44 24 08 40 20 10 	movl   $0xf0102040,0x8(%esp)
f0100995:	f0 
f0100996:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
f010099d:	00 
f010099e:	c7 04 24 6c 20 10 f0 	movl   $0xf010206c,(%esp)
f01009a5:	e8 ea f6 ff ff       	call   f0100094 <_panic>

f01009aa <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01009aa:	55                   	push   %ebp
f01009ab:	89 e5                	mov    %esp,%ebp
f01009ad:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01009ae:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f01009b5:	74 3b                	je     f01009f2 <page_init+0x48>
f01009b7:	8b 1d 5c 35 11 f0    	mov    0xf011355c,%ebx
f01009bd:	b8 00 00 00 00       	mov    $0x0,%eax
		pages[i].pp_ref = 0;
f01009c2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01009c9:	89 d1                	mov    %edx,%ecx
f01009cb:	03 0d 68 39 11 f0    	add    0xf0113968,%ecx
f01009d1:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f01009d7:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f01009d9:	89 d3                	mov    %edx,%ebx
f01009db:	03 1d 68 39 11 f0    	add    0xf0113968,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01009e1:	83 c0 01             	add    $0x1,%eax
f01009e4:	39 05 60 39 11 f0    	cmp    %eax,0xf0113960
f01009ea:	77 d6                	ja     f01009c2 <page_init+0x18>
f01009ec:	89 1d 5c 35 11 f0    	mov    %ebx,0xf011355c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01009f2:	5b                   	pop    %ebx
f01009f3:	5d                   	pop    %ebp
f01009f4:	c3                   	ret    

f01009f5 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f01009f5:	55                   	push   %ebp
f01009f6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01009f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01009fd:	5d                   	pop    %ebp
f01009fe:	c3                   	ret    

f01009ff <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f01009ff:	55                   	push   %ebp
f0100a00:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100a02:	5d                   	pop    %ebp
f0100a03:	c3                   	ret    

f0100a04 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100a04:	55                   	push   %ebp
f0100a05:	89 e5                	mov    %esp,%ebp
f0100a07:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100a0a:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100a0f:	5d                   	pop    %ebp
f0100a10:	c3                   	ret    

f0100a11 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100a11:	55                   	push   %ebp
f0100a12:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100a14:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a19:	5d                   	pop    %ebp
f0100a1a:	c3                   	ret    

f0100a1b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0100a1b:	55                   	push   %ebp
f0100a1c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100a1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a23:	5d                   	pop    %ebp
f0100a24:	c3                   	ret    

f0100a25 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100a25:	55                   	push   %ebp
f0100a26:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100a28:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a2d:	5d                   	pop    %ebp
f0100a2e:	c3                   	ret    

f0100a2f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100a2f:	55                   	push   %ebp
f0100a30:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100a32:	5d                   	pop    %ebp
f0100a33:	c3                   	ret    

f0100a34 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100a34:	55                   	push   %ebp
f0100a35:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a37:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a3a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100a3d:	5d                   	pop    %ebp
f0100a3e:	c3                   	ret    
	...

f0100a40 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100a40:	55                   	push   %ebp
f0100a41:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100a43:	ba 70 00 00 00       	mov    $0x70,%edx
f0100a48:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a4b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100a4c:	b2 71                	mov    $0x71,%dl
f0100a4e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100a4f:	0f b6 c0             	movzbl %al,%eax
}
f0100a52:	5d                   	pop    %ebp
f0100a53:	c3                   	ret    

f0100a54 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100a54:	55                   	push   %ebp
f0100a55:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100a57:	ba 70 00 00 00       	mov    $0x70,%edx
f0100a5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a5f:	ee                   	out    %al,(%dx)
f0100a60:	b2 71                	mov    $0x71,%dl
f0100a62:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a65:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100a66:	5d                   	pop    %ebp
f0100a67:	c3                   	ret    

f0100a68 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
f0100a6b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a71:	89 04 24             	mov    %eax,(%esp)
f0100a74:	e8 79 fb ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0100a79:	c9                   	leave  
f0100a7a:	c3                   	ret    

f0100a7b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a7b:	55                   	push   %ebp
f0100a7c:	89 e5                	mov    %esp,%ebp
f0100a7e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a81:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a88:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a92:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a96:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a9d:	c7 04 24 68 0a 10 f0 	movl   $0xf0100a68,(%esp)
f0100aa4:	e8 a1 04 00 00       	call   f0100f4a <vprintfmt>
	return cnt;
}
f0100aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aac:	c9                   	leave  
f0100aad:	c3                   	ret    

f0100aae <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100aae:	55                   	push   %ebp
f0100aaf:	89 e5                	mov    %esp,%ebp
f0100ab1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ab4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100ab7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100abb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100abe:	89 04 24             	mov    %eax,(%esp)
f0100ac1:	e8 b5 ff ff ff       	call   f0100a7b <vcprintf>
	va_end(ap);

	return cnt;
}
f0100ac6:	c9                   	leave  
f0100ac7:	c3                   	ret    

f0100ac8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100ac8:	55                   	push   %ebp
f0100ac9:	89 e5                	mov    %esp,%ebp
f0100acb:	57                   	push   %edi
f0100acc:	56                   	push   %esi
f0100acd:	53                   	push   %ebx
f0100ace:	83 ec 10             	sub    $0x10,%esp
f0100ad1:	89 c3                	mov    %eax,%ebx
f0100ad3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100ad6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100ad9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100adc:	8b 0a                	mov    (%edx),%ecx
f0100ade:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae1:	8b 00                	mov    (%eax),%eax
f0100ae3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ae6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100aed:	eb 77                	jmp    f0100b66 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100aef:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100af2:	01 c8                	add    %ecx,%eax
f0100af4:	bf 02 00 00 00       	mov    $0x2,%edi
f0100af9:	99                   	cltd   
f0100afa:	f7 ff                	idiv   %edi
f0100afc:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100afe:	eb 01                	jmp    f0100b01 <stab_binsearch+0x39>
			m--;
f0100b00:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b01:	39 ca                	cmp    %ecx,%edx
f0100b03:	7c 1d                	jl     f0100b22 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b05:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b08:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100b0d:	39 f7                	cmp    %esi,%edi
f0100b0f:	75 ef                	jne    f0100b00 <stab_binsearch+0x38>
f0100b11:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b14:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100b17:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100b1b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b1e:	73 18                	jae    f0100b38 <stab_binsearch+0x70>
f0100b20:	eb 05                	jmp    f0100b27 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100b22:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100b25:	eb 3f                	jmp    f0100b66 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100b27:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b2a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100b2c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b2f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b36:	eb 2e                	jmp    f0100b66 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b38:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b3b:	76 15                	jbe    f0100b52 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100b3d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b40:	4f                   	dec    %edi
f0100b41:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100b44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b47:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b49:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b50:	eb 14                	jmp    f0100b66 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b52:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b55:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b58:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100b5a:	ff 45 0c             	incl   0xc(%ebp)
f0100b5d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b5f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100b66:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100b69:	7e 84                	jle    f0100aef <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b6b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100b6f:	75 0d                	jne    f0100b7e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100b71:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b74:	8b 02                	mov    (%edx),%eax
f0100b76:	48                   	dec    %eax
f0100b77:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b7a:	89 01                	mov    %eax,(%ecx)
f0100b7c:	eb 22                	jmp    f0100ba0 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b7e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b81:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b83:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b86:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b88:	eb 01                	jmp    f0100b8b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b8a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b8b:	39 c1                	cmp    %eax,%ecx
f0100b8d:	7d 0c                	jge    f0100b9b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b8f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100b92:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100b97:	39 f2                	cmp    %esi,%edx
f0100b99:	75 ef                	jne    f0100b8a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b9b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b9e:	89 02                	mov    %eax,(%edx)
	}
}
f0100ba0:	83 c4 10             	add    $0x10,%esp
f0100ba3:	5b                   	pop    %ebx
f0100ba4:	5e                   	pop    %esi
f0100ba5:	5f                   	pop    %edi
f0100ba6:	5d                   	pop    %ebp
f0100ba7:	c3                   	ret    

f0100ba8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ba8:	55                   	push   %ebp
f0100ba9:	89 e5                	mov    %esp,%ebp
f0100bab:	83 ec 58             	sub    $0x58,%esp
f0100bae:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100bb1:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100bb4:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100bb7:	8b 75 08             	mov    0x8(%ebp),%esi
f0100bba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bbd:	c7 03 78 20 10 f0    	movl   $0xf0102078,(%ebx)
	info->eip_line = 0;
f0100bc3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bca:	c7 43 08 78 20 10 f0 	movl   $0xf0102078,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100bd1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100bd8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bdb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100be2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100be8:	76 12                	jbe    f0100bfc <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bea:	b8 00 81 10 f0       	mov    $0xf0108100,%eax
f0100bef:	3d 4d 65 10 f0       	cmp    $0xf010654d,%eax
f0100bf4:	0f 86 d8 01 00 00    	jbe    f0100dd2 <debuginfo_eip+0x22a>
f0100bfa:	eb 1c                	jmp    f0100c18 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100bfc:	c7 44 24 08 82 20 10 	movl   $0xf0102082,0x8(%esp)
f0100c03:	f0 
f0100c04:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100c0b:	00 
f0100c0c:	c7 04 24 8f 20 10 f0 	movl   $0xf010208f,(%esp)
f0100c13:	e8 7c f4 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c1d:	80 3d ff 80 10 f0 00 	cmpb   $0x0,0xf01080ff
f0100c24:	0f 85 b4 01 00 00    	jne    f0100dde <debuginfo_eip+0x236>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c2a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c31:	b8 4c 65 10 f0       	mov    $0xf010654c,%eax
f0100c36:	2d b0 22 10 f0       	sub    $0xf01022b0,%eax
f0100c3b:	c1 f8 02             	sar    $0x2,%eax
f0100c3e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c44:	83 e8 01             	sub    $0x1,%eax
f0100c47:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c4a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c4e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c55:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c58:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c5b:	b8 b0 22 10 f0       	mov    $0xf01022b0,%eax
f0100c60:	e8 63 fe ff ff       	call   f0100ac8 <stab_binsearch>
	if (lfile == 0)
f0100c65:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100c68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100c6d:	85 d2                	test   %edx,%edx
f0100c6f:	0f 84 69 01 00 00    	je     f0100dde <debuginfo_eip+0x236>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c75:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100c78:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c7b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c7e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c82:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c89:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c8c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c8f:	b8 b0 22 10 f0       	mov    $0xf01022b0,%eax
f0100c94:	e8 2f fe ff ff       	call   f0100ac8 <stab_binsearch>

	if (lfun <= rfun) {
f0100c99:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c9c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c9f:	39 d0                	cmp    %edx,%eax
f0100ca1:	7f 3d                	jg     f0100ce0 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ca3:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100ca6:	8d b9 b0 22 10 f0    	lea    -0xfefdd50(%ecx),%edi
f0100cac:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100caf:	8b 89 b0 22 10 f0    	mov    -0xfefdd50(%ecx),%ecx
f0100cb5:	bf 00 81 10 f0       	mov    $0xf0108100,%edi
f0100cba:	81 ef 4d 65 10 f0    	sub    $0xf010654d,%edi
f0100cc0:	39 f9                	cmp    %edi,%ecx
f0100cc2:	73 09                	jae    f0100ccd <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100cc4:	81 c1 4d 65 10 f0    	add    $0xf010654d,%ecx
f0100cca:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ccd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100cd0:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100cd3:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100cd6:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100cd8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100cdb:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100cde:	eb 0f                	jmp    f0100cef <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ce0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100ce3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ce6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ce9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cec:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100cef:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100cf6:	00 
f0100cf7:	8b 43 08             	mov    0x8(%ebx),%eax
f0100cfa:	89 04 24             	mov    %eax,(%esp)
f0100cfd:	e8 fd 08 00 00       	call   f01015ff <strfind>
f0100d02:	2b 43 08             	sub    0x8(%ebx),%eax
f0100d05:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d08:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d0c:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100d13:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d16:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d19:	b8 b0 22 10 f0       	mov    $0xf01022b0,%eax
f0100d1e:	e8 a5 fd ff ff       	call   f0100ac8 <stab_binsearch>
        //not need to check, we've already found the function,right?
        info->eip_line = lline;
f0100d23:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100d26:	89 73 04             	mov    %esi,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d29:	89 f0                	mov    %esi,%eax
f0100d2b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d2e:	39 ce                	cmp    %ecx,%esi
f0100d30:	7c 5f                	jl     f0100d91 <debuginfo_eip+0x1e9>
	       && stabs[lline].n_type != N_SOL
f0100d32:	89 f2                	mov    %esi,%edx
f0100d34:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100d37:	80 be b4 22 10 f0 84 	cmpb   $0x84,-0xfefdd4c(%esi)
f0100d3e:	75 18                	jne    f0100d58 <debuginfo_eip+0x1b0>
f0100d40:	eb 30                	jmp    f0100d72 <debuginfo_eip+0x1ca>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d42:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d45:	39 c1                	cmp    %eax,%ecx
f0100d47:	7f 48                	jg     f0100d91 <debuginfo_eip+0x1e9>
	       && stabs[lline].n_type != N_SOL
f0100d49:	89 c2                	mov    %eax,%edx
f0100d4b:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100d4e:	80 3c b5 b4 22 10 f0 	cmpb   $0x84,-0xfefdd4c(,%esi,4)
f0100d55:	84 
f0100d56:	74 1a                	je     f0100d72 <debuginfo_eip+0x1ca>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d58:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d5b:	8d 14 95 b0 22 10 f0 	lea    -0xfefdd50(,%edx,4),%edx
f0100d62:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100d66:	75 da                	jne    f0100d42 <debuginfo_eip+0x19a>
f0100d68:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100d6c:	74 d4                	je     f0100d42 <debuginfo_eip+0x19a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d6e:	39 c1                	cmp    %eax,%ecx
f0100d70:	7f 1f                	jg     f0100d91 <debuginfo_eip+0x1e9>
f0100d72:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d75:	8b 80 b0 22 10 f0    	mov    -0xfefdd50(%eax),%eax
f0100d7b:	ba 00 81 10 f0       	mov    $0xf0108100,%edx
f0100d80:	81 ea 4d 65 10 f0    	sub    $0xf010654d,%edx
f0100d86:	39 d0                	cmp    %edx,%eax
f0100d88:	73 07                	jae    f0100d91 <debuginfo_eip+0x1e9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d8a:	05 4d 65 10 f0       	add    $0xf010654d,%eax
f0100d8f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d91:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d94:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d97:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d9c:	39 ca                	cmp    %ecx,%edx
f0100d9e:	7d 3e                	jge    f0100dde <debuginfo_eip+0x236>
		for (lline = lfun + 1;
f0100da0:	83 c2 01             	add    $0x1,%edx
f0100da3:	39 d1                	cmp    %edx,%ecx
f0100da5:	7e 37                	jle    f0100dde <debuginfo_eip+0x236>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100da7:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100daa:	80 be b4 22 10 f0 a0 	cmpb   $0xa0,-0xfefdd4c(%esi)
f0100db1:	75 2b                	jne    f0100dde <debuginfo_eip+0x236>
		     lline++)
			info->eip_fn_narg++;
f0100db3:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100db7:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100dba:	39 d1                	cmp    %edx,%ecx
f0100dbc:	7e 1b                	jle    f0100dd9 <debuginfo_eip+0x231>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dbe:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100dc1:	80 3c 85 b4 22 10 f0 	cmpb   $0xa0,-0xfefdd4c(,%eax,4)
f0100dc8:	a0 
f0100dc9:	74 e8                	je     f0100db3 <debuginfo_eip+0x20b>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100dcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd0:	eb 0c                	jmp    f0100dde <debuginfo_eip+0x236>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100dd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dd7:	eb 05                	jmp    f0100dde <debuginfo_eip+0x236>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100dd9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100dde:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100de1:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100de4:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100de7:	89 ec                	mov    %ebp,%esp
f0100de9:	5d                   	pop    %ebp
f0100dea:	c3                   	ret    
f0100deb:	00 00                	add    %al,(%eax)
f0100ded:	00 00                	add    %al,(%eax)
	...

f0100df0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100df0:	55                   	push   %ebp
f0100df1:	89 e5                	mov    %esp,%ebp
f0100df3:	57                   	push   %edi
f0100df4:	56                   	push   %esi
f0100df5:	53                   	push   %ebx
f0100df6:	83 ec 3c             	sub    $0x3c,%esp
f0100df9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dfc:	89 d7                	mov    %edx,%edi
f0100dfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e01:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e07:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e0a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e0d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e15:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100e18:	72 11                	jb     f0100e2b <printnum+0x3b>
f0100e1a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e1d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e20:	76 09                	jbe    f0100e2b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e22:	83 eb 01             	sub    $0x1,%ebx
f0100e25:	85 db                	test   %ebx,%ebx
f0100e27:	7f 51                	jg     f0100e7a <printnum+0x8a>
f0100e29:	eb 5e                	jmp    f0100e89 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e2b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100e2f:	83 eb 01             	sub    $0x1,%ebx
f0100e32:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e36:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e39:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e3d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100e41:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100e45:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e4c:	00 
f0100e4d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e50:	89 04 24             	mov    %eax,(%esp)
f0100e53:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e56:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e5a:	e8 21 0a 00 00       	call   f0101880 <__udivdi3>
f0100e5f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e63:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e67:	89 04 24             	mov    %eax,(%esp)
f0100e6a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e6e:	89 fa                	mov    %edi,%edx
f0100e70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e73:	e8 78 ff ff ff       	call   f0100df0 <printnum>
f0100e78:	eb 0f                	jmp    f0100e89 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e7a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e7e:	89 34 24             	mov    %esi,(%esp)
f0100e81:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e84:	83 eb 01             	sub    $0x1,%ebx
f0100e87:	75 f1                	jne    f0100e7a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e89:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e8d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e91:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e94:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e98:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e9f:	00 
f0100ea0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ea3:	89 04 24             	mov    %eax,(%esp)
f0100ea6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ea9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ead:	e8 de 0a 00 00       	call   f0101990 <__umoddi3>
f0100eb2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eb6:	0f be 80 9d 20 10 f0 	movsbl -0xfefdf63(%eax),%eax
f0100ebd:	89 04 24             	mov    %eax,(%esp)
f0100ec0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100ec3:	83 c4 3c             	add    $0x3c,%esp
f0100ec6:	5b                   	pop    %ebx
f0100ec7:	5e                   	pop    %esi
f0100ec8:	5f                   	pop    %edi
f0100ec9:	5d                   	pop    %ebp
f0100eca:	c3                   	ret    

f0100ecb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ecb:	55                   	push   %ebp
f0100ecc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ece:	83 fa 01             	cmp    $0x1,%edx
f0100ed1:	7e 0e                	jle    f0100ee1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100ed3:	8b 10                	mov    (%eax),%edx
f0100ed5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100ed8:	89 08                	mov    %ecx,(%eax)
f0100eda:	8b 02                	mov    (%edx),%eax
f0100edc:	8b 52 04             	mov    0x4(%edx),%edx
f0100edf:	eb 22                	jmp    f0100f03 <getuint+0x38>
	else if (lflag)
f0100ee1:	85 d2                	test   %edx,%edx
f0100ee3:	74 10                	je     f0100ef5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ee5:	8b 10                	mov    (%eax),%edx
f0100ee7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eea:	89 08                	mov    %ecx,(%eax)
f0100eec:	8b 02                	mov    (%edx),%eax
f0100eee:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ef3:	eb 0e                	jmp    f0100f03 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ef5:	8b 10                	mov    (%eax),%edx
f0100ef7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100efa:	89 08                	mov    %ecx,(%eax)
f0100efc:	8b 02                	mov    (%edx),%eax
f0100efe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100f03:	5d                   	pop    %ebp
f0100f04:	c3                   	ret    

f0100f05 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f05:	55                   	push   %ebp
f0100f06:	89 e5                	mov    %esp,%ebp
f0100f08:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f0b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f0f:	8b 10                	mov    (%eax),%edx
f0100f11:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f14:	73 0a                	jae    f0100f20 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f16:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100f19:	88 0a                	mov    %cl,(%edx)
f0100f1b:	83 c2 01             	add    $0x1,%edx
f0100f1e:	89 10                	mov    %edx,(%eax)
}
f0100f20:	5d                   	pop    %ebp
f0100f21:	c3                   	ret    

f0100f22 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100f22:	55                   	push   %ebp
f0100f23:	89 e5                	mov    %esp,%ebp
f0100f25:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100f28:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f2f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f32:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f40:	89 04 24             	mov    %eax,(%esp)
f0100f43:	e8 02 00 00 00       	call   f0100f4a <vprintfmt>
	va_end(ap);
}
f0100f48:	c9                   	leave  
f0100f49:	c3                   	ret    

f0100f4a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f4a:	55                   	push   %ebp
f0100f4b:	89 e5                	mov    %esp,%ebp
f0100f4d:	57                   	push   %edi
f0100f4e:	56                   	push   %esi
f0100f4f:	53                   	push   %ebx
f0100f50:	83 ec 4c             	sub    $0x4c,%esp
f0100f53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f56:	8b 75 10             	mov    0x10(%ebp),%esi
f0100f59:	eb 12                	jmp    f0100f6d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f5b:	85 c0                	test   %eax,%eax
f0100f5d:	0f 84 a9 03 00 00    	je     f010130c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0100f63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f67:	89 04 24             	mov    %eax,(%esp)
f0100f6a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f6d:	0f b6 06             	movzbl (%esi),%eax
f0100f70:	83 c6 01             	add    $0x1,%esi
f0100f73:	83 f8 25             	cmp    $0x25,%eax
f0100f76:	75 e3                	jne    f0100f5b <vprintfmt+0x11>
f0100f78:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100f7c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100f83:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100f88:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f8f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f94:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f97:	eb 2b                	jmp    f0100fc4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f99:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f9c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100fa0:	eb 22                	jmp    f0100fc4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100fa5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100fa9:	eb 19                	jmp    f0100fc4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fab:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100fae:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100fb5:	eb 0d                	jmp    f0100fc4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100fb7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fbd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc4:	0f b6 06             	movzbl (%esi),%eax
f0100fc7:	0f b6 d0             	movzbl %al,%edx
f0100fca:	8d 7e 01             	lea    0x1(%esi),%edi
f0100fcd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100fd0:	83 e8 23             	sub    $0x23,%eax
f0100fd3:	3c 55                	cmp    $0x55,%al
f0100fd5:	0f 87 0b 03 00 00    	ja     f01012e6 <vprintfmt+0x39c>
f0100fdb:	0f b6 c0             	movzbl %al,%eax
f0100fde:	ff 24 85 2c 21 10 f0 	jmp    *-0xfefded4(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100fe5:	83 ea 30             	sub    $0x30,%edx
f0100fe8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100feb:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100fef:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100ff5:	83 fa 09             	cmp    $0x9,%edx
f0100ff8:	77 4a                	ja     f0101044 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ffd:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0101000:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0101003:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101007:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010100a:	8d 50 d0             	lea    -0x30(%eax),%edx
f010100d:	83 fa 09             	cmp    $0x9,%edx
f0101010:	76 eb                	jbe    f0100ffd <vprintfmt+0xb3>
f0101012:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101015:	eb 2d                	jmp    f0101044 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101017:	8b 45 14             	mov    0x14(%ebp),%eax
f010101a:	8d 50 04             	lea    0x4(%eax),%edx
f010101d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101020:	8b 00                	mov    (%eax),%eax
f0101022:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101025:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101028:	eb 1a                	jmp    f0101044 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010102d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101031:	79 91                	jns    f0100fc4 <vprintfmt+0x7a>
f0101033:	e9 73 ff ff ff       	jmp    f0100fab <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101038:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010103b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101042:	eb 80                	jmp    f0100fc4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0101044:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101048:	0f 89 76 ff ff ff    	jns    f0100fc4 <vprintfmt+0x7a>
f010104e:	e9 64 ff ff ff       	jmp    f0100fb7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101053:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101056:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101059:	e9 66 ff ff ff       	jmp    f0100fc4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010105e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101061:	8d 50 04             	lea    0x4(%eax),%edx
f0101064:	89 55 14             	mov    %edx,0x14(%ebp)
f0101067:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010106b:	8b 00                	mov    (%eax),%eax
f010106d:	89 04 24             	mov    %eax,(%esp)
f0101070:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101073:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101076:	e9 f2 fe ff ff       	jmp    f0100f6d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010107b:	8b 45 14             	mov    0x14(%ebp),%eax
f010107e:	8d 50 04             	lea    0x4(%eax),%edx
f0101081:	89 55 14             	mov    %edx,0x14(%ebp)
f0101084:	8b 00                	mov    (%eax),%eax
f0101086:	89 c2                	mov    %eax,%edx
f0101088:	c1 fa 1f             	sar    $0x1f,%edx
f010108b:	31 d0                	xor    %edx,%eax
f010108d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010108f:	83 f8 06             	cmp    $0x6,%eax
f0101092:	7f 0b                	jg     f010109f <vprintfmt+0x155>
f0101094:	8b 14 85 84 22 10 f0 	mov    -0xfefdd7c(,%eax,4),%edx
f010109b:	85 d2                	test   %edx,%edx
f010109d:	75 23                	jne    f01010c2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010109f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010a3:	c7 44 24 08 b5 20 10 	movl   $0xf01020b5,0x8(%esp)
f01010aa:	f0 
f01010ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010af:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010b2:	89 3c 24             	mov    %edi,(%esp)
f01010b5:	e8 68 fe ff ff       	call   f0100f22 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ba:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01010bd:	e9 ab fe ff ff       	jmp    f0100f6d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01010c2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01010c6:	c7 44 24 08 be 20 10 	movl   $0xf01020be,0x8(%esp)
f01010cd:	f0 
f01010ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010d5:	89 3c 24             	mov    %edi,(%esp)
f01010d8:	e8 45 fe ff ff       	call   f0100f22 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010dd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01010e0:	e9 88 fe ff ff       	jmp    f0100f6d <vprintfmt+0x23>
f01010e5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01010e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01010ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f1:	8d 50 04             	lea    0x4(%eax),%edx
f01010f4:	89 55 14             	mov    %edx,0x14(%ebp)
f01010f7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01010f9:	85 f6                	test   %esi,%esi
f01010fb:	ba ae 20 10 f0       	mov    $0xf01020ae,%edx
f0101100:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101103:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101107:	7e 06                	jle    f010110f <vprintfmt+0x1c5>
f0101109:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010110d:	75 10                	jne    f010111f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010110f:	0f be 06             	movsbl (%esi),%eax
f0101112:	83 c6 01             	add    $0x1,%esi
f0101115:	85 c0                	test   %eax,%eax
f0101117:	0f 85 86 00 00 00    	jne    f01011a3 <vprintfmt+0x259>
f010111d:	eb 76                	jmp    f0101195 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010111f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101123:	89 34 24             	mov    %esi,(%esp)
f0101126:	e8 60 03 00 00       	call   f010148b <strnlen>
f010112b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010112e:	29 c2                	sub    %eax,%edx
f0101130:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101133:	85 d2                	test   %edx,%edx
f0101135:	7e d8                	jle    f010110f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101137:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010113b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010113e:	89 d6                	mov    %edx,%esi
f0101140:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101143:	89 c7                	mov    %eax,%edi
f0101145:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101149:	89 3c 24             	mov    %edi,(%esp)
f010114c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010114f:	83 ee 01             	sub    $0x1,%esi
f0101152:	75 f1                	jne    f0101145 <vprintfmt+0x1fb>
f0101154:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101157:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010115a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010115d:	eb b0                	jmp    f010110f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010115f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101163:	74 18                	je     f010117d <vprintfmt+0x233>
f0101165:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101168:	83 fa 5e             	cmp    $0x5e,%edx
f010116b:	76 10                	jbe    f010117d <vprintfmt+0x233>
					putch('?', putdat);
f010116d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101171:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101178:	ff 55 08             	call   *0x8(%ebp)
f010117b:	eb 0a                	jmp    f0101187 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010117d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101181:	89 04 24             	mov    %eax,(%esp)
f0101184:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101187:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010118b:	0f be 06             	movsbl (%esi),%eax
f010118e:	83 c6 01             	add    $0x1,%esi
f0101191:	85 c0                	test   %eax,%eax
f0101193:	75 0e                	jne    f01011a3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101195:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101198:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010119c:	7f 16                	jg     f01011b4 <vprintfmt+0x26a>
f010119e:	e9 ca fd ff ff       	jmp    f0100f6d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011a3:	85 ff                	test   %edi,%edi
f01011a5:	78 b8                	js     f010115f <vprintfmt+0x215>
f01011a7:	83 ef 01             	sub    $0x1,%edi
f01011aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01011b0:	79 ad                	jns    f010115f <vprintfmt+0x215>
f01011b2:	eb e1                	jmp    f0101195 <vprintfmt+0x24b>
f01011b4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011b7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01011ba:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011be:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01011c5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01011c7:	83 ee 01             	sub    $0x1,%esi
f01011ca:	75 ee                	jne    f01011ba <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011cc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01011cf:	e9 99 fd ff ff       	jmp    f0100f6d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011d4:	83 f9 01             	cmp    $0x1,%ecx
f01011d7:	7e 10                	jle    f01011e9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01011d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011dc:	8d 50 08             	lea    0x8(%eax),%edx
f01011df:	89 55 14             	mov    %edx,0x14(%ebp)
f01011e2:	8b 30                	mov    (%eax),%esi
f01011e4:	8b 78 04             	mov    0x4(%eax),%edi
f01011e7:	eb 26                	jmp    f010120f <vprintfmt+0x2c5>
	else if (lflag)
f01011e9:	85 c9                	test   %ecx,%ecx
f01011eb:	74 12                	je     f01011ff <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01011ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f0:	8d 50 04             	lea    0x4(%eax),%edx
f01011f3:	89 55 14             	mov    %edx,0x14(%ebp)
f01011f6:	8b 30                	mov    (%eax),%esi
f01011f8:	89 f7                	mov    %esi,%edi
f01011fa:	c1 ff 1f             	sar    $0x1f,%edi
f01011fd:	eb 10                	jmp    f010120f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01011ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101202:	8d 50 04             	lea    0x4(%eax),%edx
f0101205:	89 55 14             	mov    %edx,0x14(%ebp)
f0101208:	8b 30                	mov    (%eax),%esi
f010120a:	89 f7                	mov    %esi,%edi
f010120c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010120f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101214:	85 ff                	test   %edi,%edi
f0101216:	0f 89 8c 00 00 00    	jns    f01012a8 <vprintfmt+0x35e>
				putch('-', putdat);
f010121c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101220:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101227:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010122a:	f7 de                	neg    %esi
f010122c:	83 d7 00             	adc    $0x0,%edi
f010122f:	f7 df                	neg    %edi
			}
			base = 10;
f0101231:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101236:	eb 70                	jmp    f01012a8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101238:	89 ca                	mov    %ecx,%edx
f010123a:	8d 45 14             	lea    0x14(%ebp),%eax
f010123d:	e8 89 fc ff ff       	call   f0100ecb <getuint>
f0101242:	89 c6                	mov    %eax,%esi
f0101244:	89 d7                	mov    %edx,%edi
			base = 10;
f0101246:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010124b:	eb 5b                	jmp    f01012a8 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap, lflag);
f010124d:	89 ca                	mov    %ecx,%edx
f010124f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101252:	e8 74 fc ff ff       	call   f0100ecb <getuint>
f0101257:	89 c6                	mov    %eax,%esi
f0101259:	89 d7                	mov    %edx,%edi
            base = 8;
f010125b:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f0101260:	eb 46                	jmp    f01012a8 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f0101262:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101266:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010126d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101270:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101274:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010127b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010127e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101281:	8d 50 04             	lea    0x4(%eax),%edx
f0101284:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101287:	8b 30                	mov    (%eax),%esi
f0101289:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010128e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101293:	eb 13                	jmp    f01012a8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101295:	89 ca                	mov    %ecx,%edx
f0101297:	8d 45 14             	lea    0x14(%ebp),%eax
f010129a:	e8 2c fc ff ff       	call   f0100ecb <getuint>
f010129f:	89 c6                	mov    %eax,%esi
f01012a1:	89 d7                	mov    %edx,%edi
			base = 16;
f01012a3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012a8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01012ac:	89 54 24 10          	mov    %edx,0x10(%esp)
f01012b0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01012b3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012b7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012bb:	89 34 24             	mov    %esi,(%esp)
f01012be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012c2:	89 da                	mov    %ebx,%edx
f01012c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c7:	e8 24 fb ff ff       	call   f0100df0 <printnum>
			break;
f01012cc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01012cf:	e9 99 fc ff ff       	jmp    f0100f6d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012d4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012d8:	89 14 24             	mov    %edx,(%esp)
f01012db:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012de:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01012e1:	e9 87 fc ff ff       	jmp    f0100f6d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012f1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012f4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01012f8:	0f 84 6f fc ff ff    	je     f0100f6d <vprintfmt+0x23>
f01012fe:	83 ee 01             	sub    $0x1,%esi
f0101301:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101305:	75 f7                	jne    f01012fe <vprintfmt+0x3b4>
f0101307:	e9 61 fc ff ff       	jmp    f0100f6d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010130c:	83 c4 4c             	add    $0x4c,%esp
f010130f:	5b                   	pop    %ebx
f0101310:	5e                   	pop    %esi
f0101311:	5f                   	pop    %edi
f0101312:	5d                   	pop    %ebp
f0101313:	c3                   	ret    

f0101314 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101314:	55                   	push   %ebp
f0101315:	89 e5                	mov    %esp,%ebp
f0101317:	83 ec 28             	sub    $0x28,%esp
f010131a:	8b 45 08             	mov    0x8(%ebp),%eax
f010131d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101320:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101323:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101327:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010132a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101331:	85 c0                	test   %eax,%eax
f0101333:	74 30                	je     f0101365 <vsnprintf+0x51>
f0101335:	85 d2                	test   %edx,%edx
f0101337:	7e 2c                	jle    f0101365 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101339:	8b 45 14             	mov    0x14(%ebp),%eax
f010133c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101340:	8b 45 10             	mov    0x10(%ebp),%eax
f0101343:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101347:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010134a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010134e:	c7 04 24 05 0f 10 f0 	movl   $0xf0100f05,(%esp)
f0101355:	e8 f0 fb ff ff       	call   f0100f4a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010135a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010135d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101360:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101363:	eb 05                	jmp    f010136a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101365:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010136a:	c9                   	leave  
f010136b:	c3                   	ret    

f010136c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010136c:	55                   	push   %ebp
f010136d:	89 e5                	mov    %esp,%ebp
f010136f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101372:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101375:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101379:	8b 45 10             	mov    0x10(%ebp),%eax
f010137c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101380:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101383:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101387:	8b 45 08             	mov    0x8(%ebp),%eax
f010138a:	89 04 24             	mov    %eax,(%esp)
f010138d:	e8 82 ff ff ff       	call   f0101314 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101392:	c9                   	leave  
f0101393:	c3                   	ret    
	...

f01013a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	57                   	push   %edi
f01013a4:	56                   	push   %esi
f01013a5:	53                   	push   %ebx
f01013a6:	83 ec 1c             	sub    $0x1c,%esp
f01013a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	74 10                	je     f01013c0 <readline+0x20>
		cprintf("%s", prompt);
f01013b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b4:	c7 04 24 be 20 10 f0 	movl   $0xf01020be,(%esp)
f01013bb:	e8 ee f6 ff ff       	call   f0100aae <cprintf>

	i = 0;
	echoing = iscons(0);
f01013c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c7:	e8 47 f2 ff ff       	call   f0100613 <iscons>
f01013cc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013ce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013d3:	e8 2a f2 ff ff       	call   f0100602 <getchar>
f01013d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013da:	85 c0                	test   %eax,%eax
f01013dc:	79 17                	jns    f01013f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e2:	c7 04 24 a0 22 10 f0 	movl   $0xf01022a0,(%esp)
f01013e9:	e8 c0 f6 ff ff       	call   f0100aae <cprintf>
			return NULL;
f01013ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f3:	eb 6d                	jmp    f0101462 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013f5:	83 f8 08             	cmp    $0x8,%eax
f01013f8:	74 05                	je     f01013ff <readline+0x5f>
f01013fa:	83 f8 7f             	cmp    $0x7f,%eax
f01013fd:	75 19                	jne    f0101418 <readline+0x78>
f01013ff:	85 f6                	test   %esi,%esi
f0101401:	7e 15                	jle    f0101418 <readline+0x78>
			if (echoing)
f0101403:	85 ff                	test   %edi,%edi
f0101405:	74 0c                	je     f0101413 <readline+0x73>
				cputchar('\b');
f0101407:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010140e:	e8 df f1 ff ff       	call   f01005f2 <cputchar>
			i--;
f0101413:	83 ee 01             	sub    $0x1,%esi
f0101416:	eb bb                	jmp    f01013d3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101418:	83 fb 1f             	cmp    $0x1f,%ebx
f010141b:	7e 1f                	jle    f010143c <readline+0x9c>
f010141d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101423:	7f 17                	jg     f010143c <readline+0x9c>
			if (echoing)
f0101425:	85 ff                	test   %edi,%edi
f0101427:	74 08                	je     f0101431 <readline+0x91>
				cputchar(c);
f0101429:	89 1c 24             	mov    %ebx,(%esp)
f010142c:	e8 c1 f1 ff ff       	call   f01005f2 <cputchar>
			buf[i++] = c;
f0101431:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101437:	83 c6 01             	add    $0x1,%esi
f010143a:	eb 97                	jmp    f01013d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010143c:	83 fb 0a             	cmp    $0xa,%ebx
f010143f:	74 05                	je     f0101446 <readline+0xa6>
f0101441:	83 fb 0d             	cmp    $0xd,%ebx
f0101444:	75 8d                	jne    f01013d3 <readline+0x33>
			if (echoing)
f0101446:	85 ff                	test   %edi,%edi
f0101448:	74 0c                	je     f0101456 <readline+0xb6>
				cputchar('\n');
f010144a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101451:	e8 9c f1 ff ff       	call   f01005f2 <cputchar>
			buf[i] = 0;
f0101456:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f010145d:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f0101462:	83 c4 1c             	add    $0x1c,%esp
f0101465:	5b                   	pop    %ebx
f0101466:	5e                   	pop    %esi
f0101467:	5f                   	pop    %edi
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    
f010146a:	00 00                	add    %al,(%eax)
f010146c:	00 00                	add    %al,(%eax)
	...

f0101470 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101470:	55                   	push   %ebp
f0101471:	89 e5                	mov    %esp,%ebp
f0101473:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101476:	b8 00 00 00 00       	mov    $0x0,%eax
f010147b:	80 3a 00             	cmpb   $0x0,(%edx)
f010147e:	74 09                	je     f0101489 <strlen+0x19>
		n++;
f0101480:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101483:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101487:	75 f7                	jne    f0101480 <strlen+0x10>
		n++;
	return n;
}
f0101489:	5d                   	pop    %ebp
f010148a:	c3                   	ret    

f010148b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010148b:	55                   	push   %ebp
f010148c:	89 e5                	mov    %esp,%ebp
f010148e:	53                   	push   %ebx
f010148f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101492:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101495:	b8 00 00 00 00       	mov    $0x0,%eax
f010149a:	85 c9                	test   %ecx,%ecx
f010149c:	74 1a                	je     f01014b8 <strnlen+0x2d>
f010149e:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014a1:	74 15                	je     f01014b8 <strnlen+0x2d>
f01014a3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01014a8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014aa:	39 ca                	cmp    %ecx,%edx
f01014ac:	74 0a                	je     f01014b8 <strnlen+0x2d>
f01014ae:	83 c2 01             	add    $0x1,%edx
f01014b1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01014b6:	75 f0                	jne    f01014a8 <strnlen+0x1d>
		n++;
	return n;
}
f01014b8:	5b                   	pop    %ebx
f01014b9:	5d                   	pop    %ebp
f01014ba:	c3                   	ret    

f01014bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
f01014be:	53                   	push   %ebx
f01014bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01014ca:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014ce:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01014d1:	83 c2 01             	add    $0x1,%edx
f01014d4:	84 c9                	test   %cl,%cl
f01014d6:	75 f2                	jne    f01014ca <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01014d8:	5b                   	pop    %ebx
f01014d9:	5d                   	pop    %ebp
f01014da:	c3                   	ret    

f01014db <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014db:	55                   	push   %ebp
f01014dc:	89 e5                	mov    %esp,%ebp
f01014de:	56                   	push   %esi
f01014df:	53                   	push   %ebx
f01014e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014e6:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014e9:	85 f6                	test   %esi,%esi
f01014eb:	74 18                	je     f0101505 <strncpy+0x2a>
f01014ed:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01014f2:	0f b6 1a             	movzbl (%edx),%ebx
f01014f5:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014f8:	80 3a 01             	cmpb   $0x1,(%edx)
f01014fb:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014fe:	83 c1 01             	add    $0x1,%ecx
f0101501:	39 f1                	cmp    %esi,%ecx
f0101503:	75 ed                	jne    f01014f2 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101505:	5b                   	pop    %ebx
f0101506:	5e                   	pop    %esi
f0101507:	5d                   	pop    %ebp
f0101508:	c3                   	ret    

f0101509 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101509:	55                   	push   %ebp
f010150a:	89 e5                	mov    %esp,%ebp
f010150c:	57                   	push   %edi
f010150d:	56                   	push   %esi
f010150e:	53                   	push   %ebx
f010150f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101512:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101515:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101518:	89 f8                	mov    %edi,%eax
f010151a:	85 f6                	test   %esi,%esi
f010151c:	74 2b                	je     f0101549 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010151e:	83 fe 01             	cmp    $0x1,%esi
f0101521:	74 23                	je     f0101546 <strlcpy+0x3d>
f0101523:	0f b6 0b             	movzbl (%ebx),%ecx
f0101526:	84 c9                	test   %cl,%cl
f0101528:	74 1c                	je     f0101546 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010152a:	83 ee 02             	sub    $0x2,%esi
f010152d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101532:	88 08                	mov    %cl,(%eax)
f0101534:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101537:	39 f2                	cmp    %esi,%edx
f0101539:	74 0b                	je     f0101546 <strlcpy+0x3d>
f010153b:	83 c2 01             	add    $0x1,%edx
f010153e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101542:	84 c9                	test   %cl,%cl
f0101544:	75 ec                	jne    f0101532 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101546:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101549:	29 f8                	sub    %edi,%eax
}
f010154b:	5b                   	pop    %ebx
f010154c:	5e                   	pop    %esi
f010154d:	5f                   	pop    %edi
f010154e:	5d                   	pop    %ebp
f010154f:	c3                   	ret    

f0101550 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101550:	55                   	push   %ebp
f0101551:	89 e5                	mov    %esp,%ebp
f0101553:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101556:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101559:	0f b6 01             	movzbl (%ecx),%eax
f010155c:	84 c0                	test   %al,%al
f010155e:	74 16                	je     f0101576 <strcmp+0x26>
f0101560:	3a 02                	cmp    (%edx),%al
f0101562:	75 12                	jne    f0101576 <strcmp+0x26>
		p++, q++;
f0101564:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101567:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010156b:	84 c0                	test   %al,%al
f010156d:	74 07                	je     f0101576 <strcmp+0x26>
f010156f:	83 c1 01             	add    $0x1,%ecx
f0101572:	3a 02                	cmp    (%edx),%al
f0101574:	74 ee                	je     f0101564 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101576:	0f b6 c0             	movzbl %al,%eax
f0101579:	0f b6 12             	movzbl (%edx),%edx
f010157c:	29 d0                	sub    %edx,%eax
}
f010157e:	5d                   	pop    %ebp
f010157f:	c3                   	ret    

f0101580 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101580:	55                   	push   %ebp
f0101581:	89 e5                	mov    %esp,%ebp
f0101583:	53                   	push   %ebx
f0101584:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101587:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010158a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010158d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101592:	85 d2                	test   %edx,%edx
f0101594:	74 28                	je     f01015be <strncmp+0x3e>
f0101596:	0f b6 01             	movzbl (%ecx),%eax
f0101599:	84 c0                	test   %al,%al
f010159b:	74 24                	je     f01015c1 <strncmp+0x41>
f010159d:	3a 03                	cmp    (%ebx),%al
f010159f:	75 20                	jne    f01015c1 <strncmp+0x41>
f01015a1:	83 ea 01             	sub    $0x1,%edx
f01015a4:	74 13                	je     f01015b9 <strncmp+0x39>
		n--, p++, q++;
f01015a6:	83 c1 01             	add    $0x1,%ecx
f01015a9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015ac:	0f b6 01             	movzbl (%ecx),%eax
f01015af:	84 c0                	test   %al,%al
f01015b1:	74 0e                	je     f01015c1 <strncmp+0x41>
f01015b3:	3a 03                	cmp    (%ebx),%al
f01015b5:	74 ea                	je     f01015a1 <strncmp+0x21>
f01015b7:	eb 08                	jmp    f01015c1 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015b9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015be:	5b                   	pop    %ebx
f01015bf:	5d                   	pop    %ebp
f01015c0:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015c1:	0f b6 01             	movzbl (%ecx),%eax
f01015c4:	0f b6 13             	movzbl (%ebx),%edx
f01015c7:	29 d0                	sub    %edx,%eax
f01015c9:	eb f3                	jmp    f01015be <strncmp+0x3e>

f01015cb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015cb:	55                   	push   %ebp
f01015cc:	89 e5                	mov    %esp,%ebp
f01015ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015d5:	0f b6 10             	movzbl (%eax),%edx
f01015d8:	84 d2                	test   %dl,%dl
f01015da:	74 1c                	je     f01015f8 <strchr+0x2d>
		if (*s == c)
f01015dc:	38 ca                	cmp    %cl,%dl
f01015de:	75 09                	jne    f01015e9 <strchr+0x1e>
f01015e0:	eb 1b                	jmp    f01015fd <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015e2:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01015e5:	38 ca                	cmp    %cl,%dl
f01015e7:	74 14                	je     f01015fd <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015e9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01015ed:	84 d2                	test   %dl,%dl
f01015ef:	75 f1                	jne    f01015e2 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01015f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01015f6:	eb 05                	jmp    f01015fd <strchr+0x32>
f01015f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015fd:	5d                   	pop    %ebp
f01015fe:	c3                   	ret    

f01015ff <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015ff:	55                   	push   %ebp
f0101600:	89 e5                	mov    %esp,%ebp
f0101602:	8b 45 08             	mov    0x8(%ebp),%eax
f0101605:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101609:	0f b6 10             	movzbl (%eax),%edx
f010160c:	84 d2                	test   %dl,%dl
f010160e:	74 14                	je     f0101624 <strfind+0x25>
		if (*s == c)
f0101610:	38 ca                	cmp    %cl,%dl
f0101612:	75 06                	jne    f010161a <strfind+0x1b>
f0101614:	eb 0e                	jmp    f0101624 <strfind+0x25>
f0101616:	38 ca                	cmp    %cl,%dl
f0101618:	74 0a                	je     f0101624 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010161a:	83 c0 01             	add    $0x1,%eax
f010161d:	0f b6 10             	movzbl (%eax),%edx
f0101620:	84 d2                	test   %dl,%dl
f0101622:	75 f2                	jne    f0101616 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101624:	5d                   	pop    %ebp
f0101625:	c3                   	ret    

f0101626 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101626:	55                   	push   %ebp
f0101627:	89 e5                	mov    %esp,%ebp
f0101629:	83 ec 0c             	sub    $0xc,%esp
f010162c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010162f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101632:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101635:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101638:	8b 45 0c             	mov    0xc(%ebp),%eax
f010163b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010163e:	85 c9                	test   %ecx,%ecx
f0101640:	74 30                	je     f0101672 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101642:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101648:	75 25                	jne    f010166f <memset+0x49>
f010164a:	f6 c1 03             	test   $0x3,%cl
f010164d:	75 20                	jne    f010166f <memset+0x49>
		c &= 0xFF;
f010164f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101652:	89 d3                	mov    %edx,%ebx
f0101654:	c1 e3 08             	shl    $0x8,%ebx
f0101657:	89 d6                	mov    %edx,%esi
f0101659:	c1 e6 18             	shl    $0x18,%esi
f010165c:	89 d0                	mov    %edx,%eax
f010165e:	c1 e0 10             	shl    $0x10,%eax
f0101661:	09 f0                	or     %esi,%eax
f0101663:	09 d0                	or     %edx,%eax
f0101665:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101667:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010166a:	fc                   	cld    
f010166b:	f3 ab                	rep stos %eax,%es:(%edi)
f010166d:	eb 03                	jmp    f0101672 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010166f:	fc                   	cld    
f0101670:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101672:	89 f8                	mov    %edi,%eax
f0101674:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101677:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010167a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010167d:	89 ec                	mov    %ebp,%esp
f010167f:	5d                   	pop    %ebp
f0101680:	c3                   	ret    

f0101681 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101681:	55                   	push   %ebp
f0101682:	89 e5                	mov    %esp,%ebp
f0101684:	83 ec 08             	sub    $0x8,%esp
f0101687:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010168a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010168d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101690:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101693:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101696:	39 c6                	cmp    %eax,%esi
f0101698:	73 36                	jae    f01016d0 <memmove+0x4f>
f010169a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010169d:	39 d0                	cmp    %edx,%eax
f010169f:	73 2f                	jae    f01016d0 <memmove+0x4f>
		s += n;
		d += n;
f01016a1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016a4:	f6 c2 03             	test   $0x3,%dl
f01016a7:	75 1b                	jne    f01016c4 <memmove+0x43>
f01016a9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016af:	75 13                	jne    f01016c4 <memmove+0x43>
f01016b1:	f6 c1 03             	test   $0x3,%cl
f01016b4:	75 0e                	jne    f01016c4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016b6:	83 ef 04             	sub    $0x4,%edi
f01016b9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016bc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016bf:	fd                   	std    
f01016c0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016c2:	eb 09                	jmp    f01016cd <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016c4:	83 ef 01             	sub    $0x1,%edi
f01016c7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016ca:	fd                   	std    
f01016cb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016cd:	fc                   	cld    
f01016ce:	eb 20                	jmp    f01016f0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016d0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016d6:	75 13                	jne    f01016eb <memmove+0x6a>
f01016d8:	a8 03                	test   $0x3,%al
f01016da:	75 0f                	jne    f01016eb <memmove+0x6a>
f01016dc:	f6 c1 03             	test   $0x3,%cl
f01016df:	75 0a                	jne    f01016eb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01016e1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01016e4:	89 c7                	mov    %eax,%edi
f01016e6:	fc                   	cld    
f01016e7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016e9:	eb 05                	jmp    f01016f0 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016eb:	89 c7                	mov    %eax,%edi
f01016ed:	fc                   	cld    
f01016ee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016f0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01016f3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01016f6:	89 ec                	mov    %ebp,%esp
f01016f8:	5d                   	pop    %ebp
f01016f9:	c3                   	ret    

f01016fa <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01016fa:	55                   	push   %ebp
f01016fb:	89 e5                	mov    %esp,%ebp
f01016fd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101700:	8b 45 10             	mov    0x10(%ebp),%eax
f0101703:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101707:	8b 45 0c             	mov    0xc(%ebp),%eax
f010170a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010170e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101711:	89 04 24             	mov    %eax,(%esp)
f0101714:	e8 68 ff ff ff       	call   f0101681 <memmove>
}
f0101719:	c9                   	leave  
f010171a:	c3                   	ret    

f010171b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010171b:	55                   	push   %ebp
f010171c:	89 e5                	mov    %esp,%ebp
f010171e:	57                   	push   %edi
f010171f:	56                   	push   %esi
f0101720:	53                   	push   %ebx
f0101721:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101724:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101727:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010172a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010172f:	85 ff                	test   %edi,%edi
f0101731:	74 37                	je     f010176a <memcmp+0x4f>
		if (*s1 != *s2)
f0101733:	0f b6 03             	movzbl (%ebx),%eax
f0101736:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101739:	83 ef 01             	sub    $0x1,%edi
f010173c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101741:	38 c8                	cmp    %cl,%al
f0101743:	74 1c                	je     f0101761 <memcmp+0x46>
f0101745:	eb 10                	jmp    f0101757 <memcmp+0x3c>
f0101747:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010174c:	83 c2 01             	add    $0x1,%edx
f010174f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101753:	38 c8                	cmp    %cl,%al
f0101755:	74 0a                	je     f0101761 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101757:	0f b6 c0             	movzbl %al,%eax
f010175a:	0f b6 c9             	movzbl %cl,%ecx
f010175d:	29 c8                	sub    %ecx,%eax
f010175f:	eb 09                	jmp    f010176a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101761:	39 fa                	cmp    %edi,%edx
f0101763:	75 e2                	jne    f0101747 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101765:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010176a:	5b                   	pop    %ebx
f010176b:	5e                   	pop    %esi
f010176c:	5f                   	pop    %edi
f010176d:	5d                   	pop    %ebp
f010176e:	c3                   	ret    

f010176f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010176f:	55                   	push   %ebp
f0101770:	89 e5                	mov    %esp,%ebp
f0101772:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101775:	89 c2                	mov    %eax,%edx
f0101777:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010177a:	39 d0                	cmp    %edx,%eax
f010177c:	73 15                	jae    f0101793 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f010177e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101782:	38 08                	cmp    %cl,(%eax)
f0101784:	75 06                	jne    f010178c <memfind+0x1d>
f0101786:	eb 0b                	jmp    f0101793 <memfind+0x24>
f0101788:	38 08                	cmp    %cl,(%eax)
f010178a:	74 07                	je     f0101793 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010178c:	83 c0 01             	add    $0x1,%eax
f010178f:	39 d0                	cmp    %edx,%eax
f0101791:	75 f5                	jne    f0101788 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101793:	5d                   	pop    %ebp
f0101794:	c3                   	ret    

f0101795 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101795:	55                   	push   %ebp
f0101796:	89 e5                	mov    %esp,%ebp
f0101798:	57                   	push   %edi
f0101799:	56                   	push   %esi
f010179a:	53                   	push   %ebx
f010179b:	8b 55 08             	mov    0x8(%ebp),%edx
f010179e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017a1:	0f b6 02             	movzbl (%edx),%eax
f01017a4:	3c 20                	cmp    $0x20,%al
f01017a6:	74 04                	je     f01017ac <strtol+0x17>
f01017a8:	3c 09                	cmp    $0x9,%al
f01017aa:	75 0e                	jne    f01017ba <strtol+0x25>
		s++;
f01017ac:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017af:	0f b6 02             	movzbl (%edx),%eax
f01017b2:	3c 20                	cmp    $0x20,%al
f01017b4:	74 f6                	je     f01017ac <strtol+0x17>
f01017b6:	3c 09                	cmp    $0x9,%al
f01017b8:	74 f2                	je     f01017ac <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017ba:	3c 2b                	cmp    $0x2b,%al
f01017bc:	75 0a                	jne    f01017c8 <strtol+0x33>
		s++;
f01017be:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01017c1:	bf 00 00 00 00       	mov    $0x0,%edi
f01017c6:	eb 10                	jmp    f01017d8 <strtol+0x43>
f01017c8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01017cd:	3c 2d                	cmp    $0x2d,%al
f01017cf:	75 07                	jne    f01017d8 <strtol+0x43>
		s++, neg = 1;
f01017d1:	83 c2 01             	add    $0x1,%edx
f01017d4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017d8:	85 db                	test   %ebx,%ebx
f01017da:	0f 94 c0             	sete   %al
f01017dd:	74 05                	je     f01017e4 <strtol+0x4f>
f01017df:	83 fb 10             	cmp    $0x10,%ebx
f01017e2:	75 15                	jne    f01017f9 <strtol+0x64>
f01017e4:	80 3a 30             	cmpb   $0x30,(%edx)
f01017e7:	75 10                	jne    f01017f9 <strtol+0x64>
f01017e9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01017ed:	75 0a                	jne    f01017f9 <strtol+0x64>
		s += 2, base = 16;
f01017ef:	83 c2 02             	add    $0x2,%edx
f01017f2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017f7:	eb 13                	jmp    f010180c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f01017f9:	84 c0                	test   %al,%al
f01017fb:	74 0f                	je     f010180c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01017fd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101802:	80 3a 30             	cmpb   $0x30,(%edx)
f0101805:	75 05                	jne    f010180c <strtol+0x77>
		s++, base = 8;
f0101807:	83 c2 01             	add    $0x1,%edx
f010180a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010180c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101811:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101813:	0f b6 0a             	movzbl (%edx),%ecx
f0101816:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101819:	80 fb 09             	cmp    $0x9,%bl
f010181c:	77 08                	ja     f0101826 <strtol+0x91>
			dig = *s - '0';
f010181e:	0f be c9             	movsbl %cl,%ecx
f0101821:	83 e9 30             	sub    $0x30,%ecx
f0101824:	eb 1e                	jmp    f0101844 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101826:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101829:	80 fb 19             	cmp    $0x19,%bl
f010182c:	77 08                	ja     f0101836 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010182e:	0f be c9             	movsbl %cl,%ecx
f0101831:	83 e9 57             	sub    $0x57,%ecx
f0101834:	eb 0e                	jmp    f0101844 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101836:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101839:	80 fb 19             	cmp    $0x19,%bl
f010183c:	77 14                	ja     f0101852 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010183e:	0f be c9             	movsbl %cl,%ecx
f0101841:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101844:	39 f1                	cmp    %esi,%ecx
f0101846:	7d 0e                	jge    f0101856 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101848:	83 c2 01             	add    $0x1,%edx
f010184b:	0f af c6             	imul   %esi,%eax
f010184e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101850:	eb c1                	jmp    f0101813 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101852:	89 c1                	mov    %eax,%ecx
f0101854:	eb 02                	jmp    f0101858 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101856:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101858:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010185c:	74 05                	je     f0101863 <strtol+0xce>
		*endptr = (char *) s;
f010185e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101861:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101863:	89 ca                	mov    %ecx,%edx
f0101865:	f7 da                	neg    %edx
f0101867:	85 ff                	test   %edi,%edi
f0101869:	0f 45 c2             	cmovne %edx,%eax
}
f010186c:	5b                   	pop    %ebx
f010186d:	5e                   	pop    %esi
f010186e:	5f                   	pop    %edi
f010186f:	5d                   	pop    %ebp
f0101870:	c3                   	ret    
	...

f0101880 <__udivdi3>:
f0101880:	83 ec 1c             	sub    $0x1c,%esp
f0101883:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101887:	89 74 24 10          	mov    %esi,0x10(%esp)
f010188b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010188f:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101893:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101897:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010189b:	85 c0                	test   %eax,%eax
f010189d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01018a1:	89 cd                	mov    %ecx,%ebp
f01018a3:	89 74 24 08          	mov    %esi,0x8(%esp)
f01018a7:	75 37                	jne    f01018e0 <__udivdi3+0x60>
f01018a9:	39 f9                	cmp    %edi,%ecx
f01018ab:	77 5b                	ja     f0101908 <__udivdi3+0x88>
f01018ad:	85 c9                	test   %ecx,%ecx
f01018af:	75 0b                	jne    f01018bc <__udivdi3+0x3c>
f01018b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01018b6:	31 d2                	xor    %edx,%edx
f01018b8:	f7 f1                	div    %ecx
f01018ba:	89 c1                	mov    %eax,%ecx
f01018bc:	89 f8                	mov    %edi,%eax
f01018be:	31 d2                	xor    %edx,%edx
f01018c0:	f7 f1                	div    %ecx
f01018c2:	89 c7                	mov    %eax,%edi
f01018c4:	89 f0                	mov    %esi,%eax
f01018c6:	f7 f1                	div    %ecx
f01018c8:	89 fa                	mov    %edi,%edx
f01018ca:	89 c6                	mov    %eax,%esi
f01018cc:	89 f0                	mov    %esi,%eax
f01018ce:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018d2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018d6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018da:	83 c4 1c             	add    $0x1c,%esp
f01018dd:	c3                   	ret    
f01018de:	66 90                	xchg   %ax,%ax
f01018e0:	31 d2                	xor    %edx,%edx
f01018e2:	31 f6                	xor    %esi,%esi
f01018e4:	39 f8                	cmp    %edi,%eax
f01018e6:	77 e4                	ja     f01018cc <__udivdi3+0x4c>
f01018e8:	0f bd c8             	bsr    %eax,%ecx
f01018eb:	83 f1 1f             	xor    $0x1f,%ecx
f01018ee:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01018f2:	75 24                	jne    f0101918 <__udivdi3+0x98>
f01018f4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f01018f8:	76 04                	jbe    f01018fe <__udivdi3+0x7e>
f01018fa:	39 f8                	cmp    %edi,%eax
f01018fc:	73 ce                	jae    f01018cc <__udivdi3+0x4c>
f01018fe:	31 d2                	xor    %edx,%edx
f0101900:	be 01 00 00 00       	mov    $0x1,%esi
f0101905:	eb c5                	jmp    f01018cc <__udivdi3+0x4c>
f0101907:	90                   	nop
f0101908:	89 f0                	mov    %esi,%eax
f010190a:	89 fa                	mov    %edi,%edx
f010190c:	f7 f1                	div    %ecx
f010190e:	31 d2                	xor    %edx,%edx
f0101910:	89 c6                	mov    %eax,%esi
f0101912:	eb b8                	jmp    f01018cc <__udivdi3+0x4c>
f0101914:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101918:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010191d:	89 c2                	mov    %eax,%edx
f010191f:	b8 20 00 00 00       	mov    $0x20,%eax
f0101924:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101928:	89 ee                	mov    %ebp,%esi
f010192a:	d3 e2                	shl    %cl,%edx
f010192c:	89 c1                	mov    %eax,%ecx
f010192e:	d3 ee                	shr    %cl,%esi
f0101930:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101935:	09 d6                	or     %edx,%esi
f0101937:	89 fa                	mov    %edi,%edx
f0101939:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010193d:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101941:	d3 e5                	shl    %cl,%ebp
f0101943:	89 c1                	mov    %eax,%ecx
f0101945:	d3 ea                	shr    %cl,%edx
f0101947:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010194c:	d3 e7                	shl    %cl,%edi
f010194e:	89 c1                	mov    %eax,%ecx
f0101950:	d3 ee                	shr    %cl,%esi
f0101952:	09 fe                	or     %edi,%esi
f0101954:	89 f0                	mov    %esi,%eax
f0101956:	f7 74 24 0c          	divl   0xc(%esp)
f010195a:	89 d7                	mov    %edx,%edi
f010195c:	89 c6                	mov    %eax,%esi
f010195e:	f7 e5                	mul    %ebp
f0101960:	39 d7                	cmp    %edx,%edi
f0101962:	72 13                	jb     f0101977 <__udivdi3+0xf7>
f0101964:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101968:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010196d:	d3 e5                	shl    %cl,%ebp
f010196f:	39 c5                	cmp    %eax,%ebp
f0101971:	73 07                	jae    f010197a <__udivdi3+0xfa>
f0101973:	39 d7                	cmp    %edx,%edi
f0101975:	75 03                	jne    f010197a <__udivdi3+0xfa>
f0101977:	83 ee 01             	sub    $0x1,%esi
f010197a:	31 d2                	xor    %edx,%edx
f010197c:	e9 4b ff ff ff       	jmp    f01018cc <__udivdi3+0x4c>
	...

f0101990 <__umoddi3>:
f0101990:	83 ec 1c             	sub    $0x1c,%esp
f0101993:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101997:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010199b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010199f:	89 74 24 10          	mov    %esi,0x10(%esp)
f01019a3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01019a7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01019ab:	85 ed                	test   %ebp,%ebp
f01019ad:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01019b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019b5:	89 cf                	mov    %ecx,%edi
f01019b7:	89 04 24             	mov    %eax,(%esp)
f01019ba:	89 f2                	mov    %esi,%edx
f01019bc:	75 1a                	jne    f01019d8 <__umoddi3+0x48>
f01019be:	39 f1                	cmp    %esi,%ecx
f01019c0:	76 4e                	jbe    f0101a10 <__umoddi3+0x80>
f01019c2:	f7 f1                	div    %ecx
f01019c4:	89 d0                	mov    %edx,%eax
f01019c6:	31 d2                	xor    %edx,%edx
f01019c8:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019cc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019d0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019d4:	83 c4 1c             	add    $0x1c,%esp
f01019d7:	c3                   	ret    
f01019d8:	39 f5                	cmp    %esi,%ebp
f01019da:	77 54                	ja     f0101a30 <__umoddi3+0xa0>
f01019dc:	0f bd c5             	bsr    %ebp,%eax
f01019df:	83 f0 1f             	xor    $0x1f,%eax
f01019e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019e6:	75 60                	jne    f0101a48 <__umoddi3+0xb8>
f01019e8:	3b 0c 24             	cmp    (%esp),%ecx
f01019eb:	0f 87 07 01 00 00    	ja     f0101af8 <__umoddi3+0x168>
f01019f1:	89 f2                	mov    %esi,%edx
f01019f3:	8b 34 24             	mov    (%esp),%esi
f01019f6:	29 ce                	sub    %ecx,%esi
f01019f8:	19 ea                	sbb    %ebp,%edx
f01019fa:	89 34 24             	mov    %esi,(%esp)
f01019fd:	8b 04 24             	mov    (%esp),%eax
f0101a00:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a08:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a0c:	83 c4 1c             	add    $0x1c,%esp
f0101a0f:	c3                   	ret    
f0101a10:	85 c9                	test   %ecx,%ecx
f0101a12:	75 0b                	jne    f0101a1f <__umoddi3+0x8f>
f0101a14:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a19:	31 d2                	xor    %edx,%edx
f0101a1b:	f7 f1                	div    %ecx
f0101a1d:	89 c1                	mov    %eax,%ecx
f0101a1f:	89 f0                	mov    %esi,%eax
f0101a21:	31 d2                	xor    %edx,%edx
f0101a23:	f7 f1                	div    %ecx
f0101a25:	8b 04 24             	mov    (%esp),%eax
f0101a28:	f7 f1                	div    %ecx
f0101a2a:	eb 98                	jmp    f01019c4 <__umoddi3+0x34>
f0101a2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a30:	89 f2                	mov    %esi,%edx
f0101a32:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a36:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a3a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a3e:	83 c4 1c             	add    $0x1c,%esp
f0101a41:	c3                   	ret    
f0101a42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a48:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a4d:	89 e8                	mov    %ebp,%eax
f0101a4f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101a54:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101a58:	89 fa                	mov    %edi,%edx
f0101a5a:	d3 e0                	shl    %cl,%eax
f0101a5c:	89 e9                	mov    %ebp,%ecx
f0101a5e:	d3 ea                	shr    %cl,%edx
f0101a60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a65:	09 c2                	or     %eax,%edx
f0101a67:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a6b:	89 14 24             	mov    %edx,(%esp)
f0101a6e:	89 f2                	mov    %esi,%edx
f0101a70:	d3 e7                	shl    %cl,%edi
f0101a72:	89 e9                	mov    %ebp,%ecx
f0101a74:	d3 ea                	shr    %cl,%edx
f0101a76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a7f:	d3 e6                	shl    %cl,%esi
f0101a81:	89 e9                	mov    %ebp,%ecx
f0101a83:	d3 e8                	shr    %cl,%eax
f0101a85:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a8a:	09 f0                	or     %esi,%eax
f0101a8c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101a90:	f7 34 24             	divl   (%esp)
f0101a93:	d3 e6                	shl    %cl,%esi
f0101a95:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101a99:	89 d6                	mov    %edx,%esi
f0101a9b:	f7 e7                	mul    %edi
f0101a9d:	39 d6                	cmp    %edx,%esi
f0101a9f:	89 c1                	mov    %eax,%ecx
f0101aa1:	89 d7                	mov    %edx,%edi
f0101aa3:	72 3f                	jb     f0101ae4 <__umoddi3+0x154>
f0101aa5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101aa9:	72 35                	jb     f0101ae0 <__umoddi3+0x150>
f0101aab:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101aaf:	29 c8                	sub    %ecx,%eax
f0101ab1:	19 fe                	sbb    %edi,%esi
f0101ab3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ab8:	89 f2                	mov    %esi,%edx
f0101aba:	d3 e8                	shr    %cl,%eax
f0101abc:	89 e9                	mov    %ebp,%ecx
f0101abe:	d3 e2                	shl    %cl,%edx
f0101ac0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ac5:	09 d0                	or     %edx,%eax
f0101ac7:	89 f2                	mov    %esi,%edx
f0101ac9:	d3 ea                	shr    %cl,%edx
f0101acb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101acf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101ad3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ad7:	83 c4 1c             	add    $0x1c,%esp
f0101ada:	c3                   	ret    
f0101adb:	90                   	nop
f0101adc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ae0:	39 d6                	cmp    %edx,%esi
f0101ae2:	75 c7                	jne    f0101aab <__umoddi3+0x11b>
f0101ae4:	89 d7                	mov    %edx,%edi
f0101ae6:	89 c1                	mov    %eax,%ecx
f0101ae8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101aec:	1b 3c 24             	sbb    (%esp),%edi
f0101aef:	eb ba                	jmp    f0101aab <__umoddi3+0x11b>
f0101af1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101af8:	39 f5                	cmp    %esi,%ebp
f0101afa:	0f 82 f1 fe ff ff    	jb     f01019f1 <__umoddi3+0x61>
f0101b00:	e9 f8 fe ff ff       	jmp    f01019fd <__umoddi3+0x6d>
