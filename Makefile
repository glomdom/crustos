TARGETS = crust
BOOT_SRC = fs/xcomp/bootlo.f fs/drv/ramdrive.f fs/xcomp/glue1.f fs/fs/fatlo.f fs/xcomp/glue2.f fs/xcomp/boothi.f
ALL_SRCS = $(shell find fs/)

all: $(TARGETS)

crust: crust.asm boot.f fatfs
	@printf "%8s %s\n" ASM $<
	@nasm -f elf32 crust.asm -o crust.o
	@printf "%8s %s\n" LD $@
	@ld -m elf_i386 crust.o -o $@

boot.f: $(BOOT_SRC)
	@printf "%8s %s -> %s\n" CAT BOOTSRC $@
	@cat $(BOOT_SRC) > $@

fatfs: $(ALL_SRCS)
	@printf "%8s %s\n" DD $@
	@dd if=/dev/zero of=$@ bs=1M count=1 status=none
	@printf "%8s %s\n" MFORMAT $@
	@mformat -M 512 -d 1 -i $@ ::
	@printf "%8s %s -> %s\n" MCOPY "fs/*" $@ 
	@mcopy -sQ -i $@ fs/* ::

pc.bin: crust
	@./crust < buildpc.f 2> $@
# @printf "%8s %s -> %s" CRUST buildpc.f $@

.PHONY: pcrun
pcrun: pc.bin
	qemu-system-i386 -drive file=pc.bin,if=floppy,format=raw

.PHONY: run
run: crust
	@stty -icanon -echo; ./crust; stty icanon echo

.PHONY: test
test: crust fatfs
	echo "f<< tests/all.f bye" | ./crust && echo "all tests passed" || (echo; exit 1)

.PHONY: cloc
cloc:
	@./codesize.sh

.PHONY: clean
clean:
	@rm -f $(TARGETS) crust.o fatfs boot.f pc.bin
	@echo "cleaned crustOS"