# Nim-Etc
Various Nim snippets collection

## setjmp_examples
This folder consists all example which taken from [Setjmp.h](https://en.wikipedia.org/wiki/Setjmp.h) page.  
Note that for ``cooperative.nim`` example, it would give ``segfault`` if it's compiled with x86-64 processor. If it's compiled to i386/x86, it will run cooperatively between ``mainTask`` and ``childTask``.
