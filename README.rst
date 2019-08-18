Tracery for Godot
=================

This is a port of `Kate Compton <http://www.galaxykate.com/>`_'s text generation library `Tracery <http://tracery.io/>`_ to 
`Godot <https://godotengine.org/>`_.

This port is based on the `Python port of Tracery <https://github.com/aparrish/pytracery>`_ by `Allison Parrish <http://www.decontextualize.com/>`_.


Installation & Usage
--------------------

See `Kate Compton's Tracery
tutorial <http://www.crystalcodepalace.com/traceryTut.html>`_ for information
about how Tracery works. In the Godot port, you use Godot dictionaries
instead of JavaScript objects for the rules, but the concept and syntax is the same. 

Example usage:

::

  extends Node2D

  # Load the tracery class, 
  var tracery_class = load("res://tracery.gd")

  func _ready():	
	# Ensure we get random values
	randomize()

        var rules = {
           'origin': '#hello.capitalize#, #location#!',
           'hello': ['hello', 'greetings', 'howdy', 'hey'],
           'location': ['world', 'solar system', 'galaxy', 'universe']
        }

	var tracery = tracery_class.new()
	var grammar = tracery.get_grammar(rules)
	print(grammar.flatten("#origin#"))  # prints, e.g., "Hello, world!"
	

Any valid Tracery grammar should work in this port. The ``base_english``
modifiers from Tracery are added automatically in the grammar but you can add your own. 
See the ``tModifiers.base_english`` func in ``tracery.gd`` for an idea of how to create
modifiers.

Note that many aspects of Tracery are not standardized, so in some edge cases
you may get output that doesn't exactly conform to what you would get if you
used the same grammar with the JavaScript version. (e.g., "null" in strings
where in JavaScript you might see "undefined")


Advanced Usage
--------------

Tracery can be used to create more than nice text. You can also extract data from the grammar tree generated. 
Example 4 in the project (shown here, see the code in ```example.gd```) demonstrates saving selections in the 
data and then getting them back from the symbols in the grammar:

::

   #Saving data
   var example4 = {
     "name": ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"],
     "animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"],
     "mood": ["vexed","indignant","impassioned","wistful","astute","courteous"],
     "story": ["#hero# traveled with her pet #heroPet#.  #hero# was never #mood#, for the #heroPet# was always too #mood#."],
     "origin": ["#[hero:#name#][heroPet:#animal#]story#"],
     }

     var grammar4 = self.tracery('#origin#', example4)
     print("Stored values >>")
     for name in grammar4.symbols.keys():
          print("    " + name + ' = ' + grammar4.symbols[name].selected_value)


Generates text like:

::

     Lina traveled with her pet coyote.  Lina was never vexed, for the coyote was always too impassioned.
     Stored values >>
          name = Lina
          animal = coyote
          mood = impassioned
          story = #hero# traveled with her pet #heroPet#.  #hero# was never #mood#, for the #heroPet# was always too #mood#.
          origin = #[hero:#name#][heroPet:#animal#]story#
          hero = Lina
          heroPet = coyote

License
-------

This port inherits Tracery's original Apache License 2.0 and the license of Allison Parrish's version. 
Note that the Apache 2.0 license means you can use this in a commercial product (but please read the license)

::
   
    Copyright 2019 Ian Sparks
    Based on code by Kate Compton and Allison Parrish

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
