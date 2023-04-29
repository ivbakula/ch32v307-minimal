ENTRY(_start)
__stack_size = 2048;
PROVIDE(_stack_size = __stack_size);

MEMORY
{
    rom(rx) :  ORIGIN = 0x00000000, LENGTH = 228K
    ram(xrw) : ORIGIN = 0x20000000, LENGTH = 32K
}

SECTIONS
{
    .init :
    {
	_start = .;
	. = ALIGN(4);
	KEEP(*(SORT_NONE(.init)))
	. = ALIGN(4);
	_einit = .;    
    } >rom AT>rom

    .vector :
    {
       	KEEP(*(SORT_NONE(.vector)));
	. = ALIGN(4);    
    } >rom AT>rom

    .text :
    {
	. = ALIGN(4);
	*(.text)
	*(.text.*)
	*(.rodata)
	*(.rodata*)
	*(.glue_7)
	*(.glue_7t)
	*(.gnu.linkonce.t.*)
	. = ALIGN(4);
    } >rom AT>rom

    .dalign :
    {
	. = ALIGN(4);
	PROVIDE(_data_vma = .);
    } >ram AT>rom
    
    .dlalign :
    {
	. = ALIGN(4);
	PROVIDE(_data_lma = .);
    } >rom AT>rom

    .data :
    {
    	*(.gnu.linkonce.r.*)
    	*(.data .data.*)
    	*(.gnu.linkonce.d.*)
	. = ALIGN(8);
    	PROVIDE( __global_pointer$ = . + 0x800 );
    	*(.sdata .sdata.*)
	*(.sdata2.*)
    	*(.gnu.linkonce.s.*)
    	. = ALIGN(8);
    	*(.srodata.cst16)
    	*(.srodata.cst8)
    	*(.srodata.cst4)
    	*(.srodata.cst2)
    	*(.srodata .srodata.*)
    	. = ALIGN(4);
	PROVIDE( _edata = .);    
    } >ram AT>rom

    .bss :
    {
	. = ALIGN(4);
	PROVIDE( _sbss = .);
  	*(.sbss*)
        *(.gnu.linkonce.sb.*)
	*(.bss*)
     	*(.gnu.linkonce.b.*)		
	*(COMMON*)
	. = ALIGN(4);
	PROVIDE( _ebss = .);    
    } >ram AT>rom

    .stack ORIGIN(ram) + LENGTH(ram) - __stack_size :
    {
        PROVIDE( _heap_end = . ); 
        . = ALIGN(4);
        PROVIDE(_susrstack = . );
        . = . + __stack_size;
        PROVIDE( _eusrstack = .);
    } >ram
}
