# Nim-Etc
Various Nim snippets collection

## setjmp_examples
This folder consists all example which taken from [Setjmp.h](https://en.wikipedia.org/wiki/Setjmp.h) page.  
Note that for ``cooperative.nim`` example, it would give ``segfault`` if it's compiled with x86-64 processor. If it's compiled to i386/x86, it will run cooperatively between ``mainTask`` and ``childTask``.

## armyfactions
This a solved problem about finding and calculating army faction within given map.  
The input is given in the file and the very first line shows how much test case should be done. While the two subsequents line show the row and column of the map.  
After that, there are several lines which draws the map.
Each army faction is labeled with lower case ascii, each plain is labeled with ``.`` and mountain is ``#`` . A faction said controlling a region if within closed space only that faction is there. If there's another faction within that space/region, it's said that region is contested. If a faction found another with the same faction, it's allied faction and should controlling the same region.  
The task was to write any regions each faction had controlled without writing any contested region. Lastly, write the total contested region within that map.  
The solution using 2 macro to illustrate on Nim ability to control how coders to code whichever they like. In short, coders are able to create any DSL they want accordingly.  
Also, the solution illustrates on DFS (deep-first search) to walk the map from any faction.  
Compile with ``-d:release`` to avoid stack overflow because of DFS while walking the map.

## UDP Server
A simple example of UDP server in Nim. Using module ``net``. Done to answer problem in forum https://forum.nim-lang.org/t/3074
