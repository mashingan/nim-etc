# implementation from original article which use java
# http://www.theprojectspot.com/tutorial-post/creating-a-genetic-algorithm-for-beginners/3
import math, random, strutils, sequtils, strformat

const
  uniformRate = 0.5
  mutationRate = 0.015
  tournamentSize = 5
  elitism = true

type
  #Individual = seq[byte]
  Individual = object
    genes: seq[byte]
    fit: int
  Population = seq[Individual]
  Solution = seq[byte]

proc asSolution(s: string): Solution =
  for c in s:
    result.add (c.ord - '0'.ord).byte

proc fitnessOf(sol: Solution, indiv: var Individual): int =
  for gene in indiv.genes.zip sol:
    if gene[0] == gene[1]: inc result

  if indiv.genes.len < sol.len:
    for i in indiv.genes.len ..< sol.len:
      let gene = 1.rand.byte
      if sol[i] == gene: inc result
      indiv.genes.add gene

proc fitness(indiv: var Individual, sol: Solution): int =
  if indiv.fit == 0:
    indiv.fit = sol.fitnessOf indiv
  result = indiv.fit

proc fittest(pops: var Population, sol: Solution): var Individual =
  result = pops[0]
  for ind in pops.mitems:
    if result.fitness(sol) <= ind.fitness(sol):
      result = ind

proc mutate(ind: var Individual) =
  ind.genes.apply do (b: var byte):
    if 1.0.rand <= mutationRate: b = 1.rand.byte
  ind.fit = 0

proc tournamentSelection(pops: Population, sol: Solution): Individual =
  var tournament = newseq[Individual](tournamentSize)
  for _ in 0 ..< tournamentSize:
    tournament.add pops.rand
  result = tournament.fittest sol

proc crossover(ida, idb: Individual): Individual =
  result.genes = newseq[byte](ida.genes.len)
  for i, genes in ida.genes.zip idb.genes:
    result.genes[i] = if 1.0.rand <= uniformRate: genes[0]
                      else: genes[1]

proc evolve(pops: var Population, sol: Solution) =
  var offset = 0
  if elitism:
    pops[0] = pops.fittest sol
    offset = 1
  for i in offset ..< pops.len:
    let
      ida = pops.tournamentSelection sol
      idb = pops.tournamentSelection sol
    pops[i] = ida.crossover idb
    mutate pops[i]

proc maxfitness(sol: Solution): int =
  sol.len

proc initIndividual(n = 32): Individual =
  result.genes = newseq[byte](n)
  for i in 0 ..< n:
    result.genes[i] = 1.rand.byte

proc initPopulation(size: int, initialized = false): Population =
  result = newseq[Individual](size)
  if initialized:
    for indiv in result.mitems:
      indiv = initIndividual()

proc main =
  randomize()
  var
    samplesol = "1111000000000000000000000000000000000000000000000000000000001111"
    sol = samplesol.asSolution
    population = 100.initPopulation(initialized = true)
    generationCount = 0
    thefittest = population.fittest sol
    thefitness = thefittest.fitness sol
  echo fmt"Max fitness solution: {sol.maxfitness}"
  echo fmt"Initial fitness: {thefitness}"
  while thefitness < sol.maxfitness:
    inc generationCount
    echo fmt"Generation: {generationCount} Fittest: {thefitness}"
    echo fmt"""Current fittest: {thefittest.genes.join("")}"""
    if generationCount >= 50:
      break
    population.evolve sol
    thefittest = population.fittest sol
    thefitness = thefittest.fitness sol
  echo "Solution found!"
  echo "Generation: ", generationCount
  echo "Genes: ", population.fittest(sol).genes.join("")

main()
