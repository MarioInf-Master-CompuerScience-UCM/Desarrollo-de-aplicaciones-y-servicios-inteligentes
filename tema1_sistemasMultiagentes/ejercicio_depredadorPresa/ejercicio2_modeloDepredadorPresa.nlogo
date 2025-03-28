breed [rabbits rabbit]
breed [wolves wolf]
breed [weathers weather]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; Variable declaration ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals [
  ;; Wolf's Variables
  wolfColour
  wolfSize
  wolfMaxEnergy
  wolfEnergyEatThreshold
  wolfEnergyReproduceThreshold
  wolfEnergyReproduceCost
  wolfReproduceProbability
  wolfEnergyBorned
  wolfMinTimeReproduce
  wolfMovement
  wolfHuntPosibility
  wolfEnergyMoveCost

  ;; rabbit's variables
  rabbitColour
  rabbitSize
  rabbitMaxEnergy
  rabbitEnergyEatThreshold
  rabbitEnergyReproduceThreshold
  rabbitEnergyReproduceCost
  rabbitReproduceProbability
  rabbitEnergyBorned
  rabbitMinTimeReproduce
  rabbitMovement
  rabbitEnergyMoveCost

  ;; Patche's variables
  grassBigColour
  grassBigMaxEnergy
  grassSmallColour
  grassSmallMaxEnergy
  grassDryColour
  grassDryMaxEnergy
  goundColour
  goundDryMaxEnergy

  ;; Weather's variables
  weatherPosX
  weatherPosY
  weatherSize
  weatherUpdateFrecuency
  sunny
  sunnyColour
  sunnyRegrowValue
  rainy
  rainyColour
  rainyRegrowValue
  warm
  warmColour
  warmRegrowValue
  cool
  coolColour
  coolRegrowValue
  numPosibleStates

  ;; Simulation's variables
  stepLimit
  maxRabbits
  maxwolves
  functionReproduce_A  ;;f(x) = a^x * ReproduceProbability

]
;;;;;

turtles-own [
  energy
  timeToLife
  randomValue
]
rabbits-own[]
wolves-own[]
weathers-own[
  state
  regrowValue
]
patches-own[
  actualEnergy
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup Code ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  initGlobals
  setupPatches
  setuprabbits
  setupWolves
  setupWeather
  reset-ticks
end


;; globals variable initialization ;;
to initGlobals

  ;; Wolf's variables
  set wolfColour 2
  set wolfSize 1.5
  set wolfMaxEnergy 50
  set wolfEnergyEatThreshold (wolfMaxEnergy - (wolfMaxEnergy / 10))
  set wolfEnergyReproduceThreshold 30
  set wolfEnergyReproduceCost 20
  set wolfReproduceProbability 10  ;;(0-100)
  set wolfEnergyBorned 10
  set wolfMinTimeReproduce 30
  set wolfMovement 1
  set wolfHuntPosibility 70  ;;(0-100)
  set wolfEnergyMoveCost 1

  ;; rabbit's variables
  set rabbitColour 9
  set rabbitSize 1
  set rabbitMaxEnergy 20
  set rabbitEnergyEatThreshold (rabbitMaxEnergy - (rabbitMaxEnergy / 10))
  set rabbitEnergyReproduceThreshold 15
  set rabbitEnergyReproduceCost 10
  set rabbitReproduceProbability 15  ;;(0-100)
  set rabbitEnergyBorned 10
  set rabbitMinTimeReproduce 5
  set rabbitMovement 1
  set rabbitEnergyMoveCost 1

  ;; Patche's variables
  set grassBigColour 64
  set grassBigMaxEnergy 10
  set grassSmallColour 57
  set grassSmallMaxEnergy 8
  set grassDryColour 48
  set grassDryMaxEnergy 2
  set goundColour 37
  set goundDryMaxEnergy 0

  ;; Weather's variables
  set weatherPosX 15
  set weatherPosY 15
  set weatherSize 3
  set weatherUpdateFrecuency 3
  set sunny 0
  set sunnyColour 46
  set sunnyRegrowValue 1
  set rainy 1
  set rainyColour 96
  set rainyRegrowValue 2
  set warm 2
  set warmColour 26
  set warmRegrowValue -1
  set cool 3
  set coolColour 76
  set coolRegrowValue 0
  set numPosibleStates 4

  ;; Simulation's variables
  set stepLimit -1
  set maxRabbits -1
  set maxwolves -1
  set functionReproduce_A -0.5


end
;;;;


to setupPatches
  ask patches [
    let value random (grassBigMaxEnergy)
    ifelse(value <= goundDryMaxEnergy)[
      set pcolor goundColour
      set actualEnergy value
    ]
    [
      ifelse(value <= grassDryMaxEnergy)[
        set pcolor grassDryColour
        set actualEnergy value
      ]
      [
        ifelse(value <= grassSmallMaxEnergy)[
          set pcolor grassSmallColour
          set actualEnergy value
        ]
        [
          if(value <= grassBigMaxEnergy)[
            set pcolor grassBigColour
            set actualEnergy value
          ]
        ]
      ]
    ]
  ]
end

to setupRabbits
  create-rabbits initialNumRabbits[
    setxy random-xcor random-ycor
    set color rabbitColour
    set size rabbitSize
    set energy ((rabbitMaxEnergy / 2) + random (rabbitMaxEnergy / 2))
    set timeToLife random (rabbitMinTimeReproduce * 2)
    ifelse show-energy?
    [ set label energy set label-color 13]
    [ set label "" ]
  ]
end

to setupWolves
  create-wolves initialNumWolves[
    setxy random-xcor random-ycor
    set color wolfColour
    set size wolfSize
    set energy ((wolfMaxEnergy / 2) + random (wolfMaxEnergy / 2))
    set timeToLife random (wolfMinTimeReproduce * 2)
    ifelse show-energy?
    [ set label energy set label-color 13]
    [ set label "" ]
  ]
end

to setupWeather
  create-weathers 1[
    setxy weatherPosX weatherPosY
    set size weatherSize
    set shape "circle"
  ]
  updateWeather
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; Go and Step Code ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if (ticks >= stepLimit and stepLimit != -1)  [
    stop
  ]
  step
  tick
end

to step
  if (ticks >= stepLimit and stepLimit != -1) [
    stop
  ]
  updateWeather
  moveTurtles
  rabbitEatGrass
  wolfEatrabbit
  reproduce
  regrow-grass
  check-death
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; Action's functions ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to moveTurtles
  ask rabbits [
    right random 360
    forward rabbitMovement
    set energy (energy - rabbitEnergyMoveCost)
    set timeToLife timeToLife + 1
    ifelse show-energy?
    [ set label energy set label-color 13]
    [ set label "" ]
  ]
  ask wolves [
    right random 360
    forward wolfMovement
    set energy (energy - wolfEnergyMoveCost)
    set timeToLife timeToLife + 1
    ifelse show-energy?
    [ set label energy set label-color 13]
    [ set label "" ]
  ]
  ask weathers [
  ]
end


to rabbitEatGrass
  ask rabbits [
    let grass patch-here
    if ([actualEnergy] of grass >= 1) and (energy < rabbitEnergyEatThreshold)[
      set energy (energy + [actualEnergy] of grass)
      if(energy > rabbitMaxEnergy)[
        set energy rabbitMaxEnergy
      ]
      set pcolor goundColour
      ask patch-here[
        set actualEnergy 0
      ]
    ]
  ]
end


to wolfEatrabbit
  ask wolves[
    let presa one-of rabbits-here

    if (presa != nobody)[
      set randomValue random 101

      if (energy < wolfEnergyEatThreshold and randomValue < wolfHuntPosibility )[
        set energy (energy + [energy] of presa)
        if(energy > wolfMaxEnergy)[set energy wolfMaxEnergy]
        ask presa[die]
      ]
    ]
  ]
end


to reproduce
  if (count rabbits < maxRabbits or maxRabbits = -1)[
    ask rabbits [
      set randomValue random 101
      if (energy > rabbitEnergyReproduceThreshold
       ;; and randomValue <= ( - rabbitReproduceProbability * (functionReproduce_A ^ ( ( round ( (count rabbits) / 100) ) + 1) ) )
        and timeToLife >= rabbitMinTimeReproduce)
      [
        set energy (energy - rabbitEnergyReproduceCost)
        hatch 1 [
          set energy rabbitEnergyBorned
          set timeToLife 0
        ]
      ]
    ]
  ]

  if (count wolves < maxWolves or maxWolves = -1)[
    ask wolves [
      set randomValue random 101
      if (energy > wolfEnergyReproduceThreshold
       ;; and randomValue <= ( - wolfReproduceProbability * (functionReproduce_A ^ ( ( round ( (count wolves) / 100) ) + 1) ) )
        and timeToLife >= wolfMinTimeReproduce)
      [
        set energy (energy - wolfEnergyReproduceCost)
        hatch 1 [
          set energy wolfEnergyBorned
          set timeToLife 0
        ]
      ]
    ]
  ]
end


to updateWeather
  ask weathers[
    set state random(numPosibleStates)
    set regrowValue state
    setxy weatherPosX weatherPosY
    ifelse(state = sunny)
    [
      set regrowValue sunnyRegrowValue
      set color sunnycolour
      set label "Sunny" set label-color black
    ]
    [
      ifelse(state = rainy)
      [
        set regrowValue rainyRegrowValue
        set color rainycolour
        set label "Rainy" set label-color black
      ]
      [
        ifelse(state = warm)
        [
          set regrowValue warmRegrowValue
          set color warmcolour
          set label "Warm" set label-color black
        ]
        [
          set regrowValue coolRegrowValue
          set color coolcolour
          set label "Cool" set label-color black
        ]
      ]
    ]
  ]
end


to check-death
  ask rabbits [
    if (energy <= 0) [ die ]
  ]
  ask wolves [
    if (energy <= 0) [ die ]
  ]
end


to regrow-grass
  ask patches [
  let actualWeather one-of weathers
    set actualEnergy (actualEnergy + [regrowValue] of actualWeather)
    ifelse(actualEnergy <= goundDryMaxEnergy)
    [set pcolor goundColour]
    [
      ifelse(actualEnergy <= grassDryMaxEnergy)
      [set pcolor grassDryColour]
      [
        ifelse(actualEnergy <= grassSmallMaxEnergy)
        [set pcolor grassSmallColour]
        [
          if(actualEnergy <= grassBigMaxEnergy)
          [set pcolor grassBigColour]
        ]
      ]
    ]

    ifelse (actualEnergy > grassBigMaxEnergy)
    [set actualEnergy grassBigMaxEnergy]
    [
      if (actualEnergy < 0)
      [set actualEnergy 0]
    ]

  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
701
11
1138
449
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
607
22
690
55
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
608
76
693
109
Step
step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
607
111
693
144
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
294
46
435
91
Número de conejos
count rabbits
17
1
11

PLOT
66
200
696
447
Estadísticas
ticks
nº agentes
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Rabbits" 1.0 0 -3026479 true "" "plot count rabbits"
"Wolves" 1.0 0 -16777216 true "" "plot count wolves"

SLIDER
66
66
247
99
initialNumRabbits
initialNumRabbits
0
100
20.0
1
1
NIL
HORIZONTAL

SWITCH
69
28
224
61
show-energy?
show-energy?
0
1
-1000

SLIDER
69
104
246
137
initialNumWolves
initialNumWolves
0
100
4.0
1
1
NIL
HORIZONTAL

MONITOR
308
97
434
142
Número de lobos
count wolves
17
1
11

@#$#@#$#@
## Descripción del modelo

El presente proyecto busca simular el funcionamiento de un modelo depredador-presa mediante la implementación de agentes. Dicho modelo se caracteriza por poner en contraposición el numero de individuos que se encuentran en dos o más grupos, ejerciendo al menos uno de ellos el rol de depredador y otro el rol de presa.


### Descripción de los agentes

En el presente modelo se incluyen los siguientes agentes:

+ Lobos: Ejercen el rol de depredador y se alimenta de de los conejos. Tienne la capacidad de reproducirse y su supervivencia esta ligada a su energía.

+ Conejos: Ejercen el rol de presa y se alimenta de de la hierba. Tienen la capacidad de reproducirse y su supervivencia esta ligada tanto a su energía como a la posibilidad de ser cadazos por un lobo.

+ Hierba: Representan el alimento principal para los conejos. No tienen la capacidad de reproducirse y su crecimiento depende del clima.

+ Clima: Influye en la cantidad de alimento disponible para las presas. Esto se basa en el estado del clima en cada comento, el cual varía de forma aleatoria. 

### Acciones llevadas a cabo en el modelo

#### Movimiento

Los agentes que representan tano a los conejos como a los lobos se moverán de manera aleatoria en cada uno de los ticks producidos a lo largo de la simulación. Cada vez que un agente se mueve, este consume una parte de su energía.

El tiempo de vida que cada uno de los agentes lleva existiendo se mide por el número de ticks que han pasado desde que apareció en el escenario, por lo que cada vez que se produce el movimiento de un determinado agente, ese incrementará el valor de su tiempo de vida.

#### Conejos comen hierba

Los conejos se alimentan en base la hierba que se encuentra en el escenario. Cuando el nivel de energía de un conejo esta por debajo de un determinado humbral y este se encuentra en una zona donde existe hierba, podrá comerla para recargar su energía con una cantidad proporcionar a la energía que disponía dicha hierba.

Los conejos únicamente pueden comer la hierba que se encuentra en el mismo sitio que ellos. Cuando esto se lleva a cabo, la hierba que existía es eliminada y se sistutuye por una zona de tierra.

#### Lobos comen conejos

Los lobos se alimentan mediante la caza de conejos. Cuando el nivel de energía de un lobo esta por debajo de un determinado humbral y este se encuentra en la misma zona que al menos un conejo, podrá cazarlo para recargar su energía con una cantidad proporcionar a la energía que disponía dicho conejo.

A veces cazar no es algo tan sencillo, por lo que cuando un lobo lo intenta dispone de una posibilidad para lobrarlo. En caso de que no haya suerte, el lobo habrá perdido su oportinidad, pero podrá volver a intentarlo en el siguiente tick.


#### Muerte por falta de alimento

Cuando un agente, ya sea un conejo o un lobo, reduce tanto su nivel de energía que este llega a cero, dicho agente morirá por causas naturales. Esta es una manera de establecer un balance entre la cantidad de hierba, conejos y lobos que existen en el escenario.


#### Reproducción

Tanto los conejos como los lobos pueden reproducirse, dando así nuevos ejemplares del mismo tipo y aumentando el número de individuos. Para que esto se lleve a cabo deben cumplirse la condición de que el nivel de energía que contiene el lobo o conejo que se quiere reproducir debe ser mañor a un determinado umbral.

Cundo se produce la reproducción, el agente que la realice perderá buena parte de su energía actual (la cual debe ser siempre menor a la energía umbral indicada anteriormente). Por otra parte, el nuevo agente aparecerá en el escenario con un porcentaje del nivel de nergía máximo que puede llegar a tener.

Además de esto, para que un agente pueda reproducirse debe haber vivido lo suficiente, es decir, su cantidad de tiempo vivido debe ser mañor a un valor determinado. Los agentes no se reproducen siempre que se cumpla lo indicado hasta ahora, sino que tienen una probabilidad para llevarlo a cabo, la cual diferente para cada tipo.


#### Actualización del clima

El clima es un factor importante dentro de los modelos depredador-presa, ya que suele influir directamente sobre la disponibilidad de alimento de alguno de sus integrantes. En nuestro caso, el clima controla directamente la cantidad de energía que tiene la hierba de la cual se nutren los conejos.

Se han configurado un total de cuatro tipos diferentes de clima, los cuales pueden actualizarse cada un número de ticks determinados. La elección del tipo de clima a aplciar cuando se actualiza se realzia de forma aleatoria, pudiendo seleccionarse incluso el mismo clima de antes de llevar a cabo la actualización.

Tipos de clima:

+ Soleado: La energía de la hierba aumenta un punto por cada tick.

+ Lluvioso: La energía de la hierba aumenta dos puntos por cada tick.

+ Frío: La energía de la hierba no aumentan ni disminuye por cada tick.

+ Seco: La energía de la hierba disminuye un punto por cada tick.


#### Crecimeinto de hierba

El crecimiento de la hierba se encuentra directamente asociado con la energía contenida en la misma en ese preciso momento. La energía que contiene la hierba siempre será mayor o igual que cero y menor o igual que un valor máximo indicado.

En cada uno de los tick producidos en el escenario, el valor contenido por la energía de la hierba varía en torno al clima. Para hacerlo más entendible de forma visual se han establecidos diferentes tipos de hierba:

+ Suelo (la energía es 0, por lo que no puede ser consumida por los conejos).
+ Hierba seca.
+ Hierba pequeña.
+ Hierba grande.

### Variables globales

#### Variables asociadas a los agentes de tipo lobo:

+ **wolfColour:** Color de los agentes de tipo lobo.
+ **wolfSize** Tamaño de los agentes de tipo lobo.
+ **wolfMaxEnergy:** Energía maxima que pueden tener los agentes de tipo lobo.
+ **wolfEnergyEatThreshold:** Valor maximo de energía que deben tener los agentes de tipo lobo para poder comer.
+ **wolfEnergyReproduceThreshold:** Valor mínimo de energía que deben tener los agentes de tipo lobo para poder reproducirse.
+ **wolfEnergyReproduceCost:** Reducción de energía aplicada a los agentes de tipo lobo cuando se reproducen.
+ **wolfReproduceProbability:** Posibilidad de reproducción que tienen los agentes de tipo lobo (el valor se establece entre 0 y 100).
+ **wolfEnergyBorned:** Valor inicial de la energía que tienen los agentes de tipo lobo cuando estos aparecen por primera vez en el escenario como resultado de la reproducción.
+ **wolfMinTimeReproduce:** Valor mínimo del tiempo de vida que deben tener los agentes de tipo lobo para poder reproducirse.
+ **wolfMovement:** Número de casillas que se mueven los agentes de tipo lobo por cada tick producido en el escenario.
+ **wolfHuntPosibility:** Posibilidad que tienen los agentes de tipo lobo para cazar exitosamente a los agente de tipo conejo.
+ **wolfEnergyMoveCost:** Valor que se reduce la energía de los agentes de tipo lobo cada vez que estos se mueven por el escenario.

#### Variables asociadas a los agentes de tipo conejo:

+ **rabbitColour:** Color de los agentes de tipo conejo.
+ **rabbitSize:** Tamaño de los agentes de tipo conejo.
+ **rabbitMaxEnergy:** Energía maxima que pueden tener los agentes de tipo conejo.
+ **rabbitEnergyEatThreshold:** Valor maximo de energía que deben tener los agentes de tipo conejo para poder comer.
+ **rabbitEnergyReproduceThreshold:** Valor mínimo de energía que deben tener los agentes de tipo conejo para poder reproducirse.
+ **rabbitEnergyReproduceCost:** Reducción de energía aplicada a los agentes de tipo conejo cuando se reproducen.
+ **rabbitReproduceProbability:** Posibilidad que tienen los agentes de tipo conejo para cazar exitosamente a los agente de tipo conejo.
+ **rabbitEnergyBorned:** Valor inicial de la energía que tienen los agentes de tipo conejo cuando estos aparecen por primera vez en el escenario como resultado de la reproducción.
+ **rabbitMinTimeReproduce:** Valor mínimo del tiempo de vida que deben tener los agentes de tipo conejo para poder reproducirse.
+ **rabbitMovement:** Número de casillas que se mueven los agentes de tipo conejo por cada tick producido en el escenario
+ **rabbitEnergyMoveCost:** Valor que se reduce la energía de los agentes de tipo conejo cada vez que estos se mueven por el escenario.

#### Variables asociadas a los bloques que componen el escenario:

+ **grassBigColour:** Color de los bloques del escenario catalogados como hierba grande.
+ **grassBigMaxEnergy:** Valor maximo de energía que pueden contener los bloques del escenario para ser catalogados como hierba grande.
+ **grassSmallColour:** Color de los bloques del escenario catalogados como hierba pequeña.
+ **grassSmallMaxEnergy:** Valor maximo de energía que pueden contener los bloques del escenario para ser catalogados como hierba pequeña.
+ **grassDryColour:** Color de los bloques del escenario catalogados como hierba seca.
+ **grassDryMaxEnergy:** Valor maximo de energía que pueden contener los bloques del escenario para ser catalogados como hierba seca.
+ **goundColour:** Color de los bloques del escenario catalogados como hierba suelo.
+ **goundDryMaxEnergy:** Valor maximo de energía que pueden contener los bloques del escenario para ser catalogados como suelo.

#### Variables asociadas a los agentes de tipo clima:

+ **weatherPosX:** Posición del agente de tipo clima en la cordenada X.
+ **weatherPosY:** Posición del agente de tipo clima en la cordenada Y.
+ **weatherSize:** Tamaño del agente de tipo clima.
+ **weatherUpdateFrecuency:** Fecuencia de actualización del clima medida en ticks.
+ **sunny:** Valor numérico para identificar el clima de tipo soleado.
+ **sunnyColour:** Color del agente cuando el tipo de clima es soleado.
+ **sunnyRegrowValue:** Valor de variación de la energía contenida en los bloques que contienen el suelo y representan la hierba cuando el clima es soleado.
+ **rainy:** Valor numérico para identificar el clima de tipo lluvioso.
+ **rainyColour:** Color del agente cuando el tipo de clima es lluvioso.
+ **rainyRegrowValue:** Valor de variación de la energía contenida en los bloques que contienen el suelo y representan la hierba cuando el clima es lluvioso.
+ **warm:** Valor numérico para identificar el clima de tipo seco.
+ **warmColour:** Color del agente cuando el tipo de clima es seco.
+ **warmRegrowValue:** Valor de variación de la energía contenida en los bloques que contienen el suelo y representan la hierba cuando el clima es seco.
+ **cool:** Valor numérico para identificar el clima de tipo frío.
+ **coolColour:** Color del agente cuando el tipo de clima es frío.
+ **coolRegrowValue:** Valor de variación de la energía contenida en los bloques que contienen el suelo y representan la hierba cuando el clima es frío.
+ **numPosibleStates:** Numero de posibles estados del clima (empleado para hacer el cambio aleatorio entre dichos estados).

#### Variables asociadas a la ejecución de la simulación:

+ **stepLimit:** Número máximo de tick que se producirán en la simulación. Si se pone el valor -1 no se aplicará este límite.
+ **maxRabbits:** Número máximo de conejos que se producirán en la simulación. Si se pone el valor -1 no se aplicará este límite.
+ **maxwolves:** Número máximo de lobos que se producirán en la simulación. Si se pone el valor -1 no se aplicará este límite.
+ **functionReproduce_A:** Valor constante de la función exponencial que regula la reproducción en base al número de ejempalares de la misma clase de agentes. *Esta función es de la forma f(x) = a^x * ReproduceProbability, donde a<0*. Esta funcionalidad no ha termiando de ser implementada de manera activa en el modelo.





@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
