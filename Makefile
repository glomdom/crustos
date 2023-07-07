TARGETS = crust
BOOT_SRC = fs/xcomp/bootlo.f fs/fs/linux.f fs/xcomp/boothi.f

all: $(TARGETS)

crust: crust.asm boot.f fatfs
	@echo " ASM      crust.asm"
	@nasm -f elf32 crust.asm -o crust.o
	@echo " LD       crust"
	@ld -m elf_i386 crust.o -o $@

boot.f: $(BOOT_SRC)
	@echo " CAT      BOOT_SRC -> $@"
	@cat $(BOOT_SRC) > $@

fatfs: fs
	@echo " DD       $@"
	@dd if=/dev/zero of=$@ bs=4M count=1 status=none
	@echo " MFORMAT  $@"
	@mformat -c 1 -d 1 -i $@ ::
	@echo " MCOPY    fs/* -> $@"
	@mcopy -sQ -i $@ fs/* ::

.PHONY: run
run: crust
	@stty -icanon -echo; ./crust; stty icanon echo

.PHONY: test
test: crust
	@echo "f<< tests/all.f bye" | ./crust && echo "all tests passed" || (echo; exit 1)

.PHONY: cloc
cloc:
	@./codesize.sh

.PHONY: clean
clean:
	@rm -f $(TARGETS) crust.o fatfs
	@echo "cleaned crustOS"