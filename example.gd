extends Node2D

# Load the tracery class, 
var tracery_class = load("res://tracery.gd")

# Called when the node enters the scene tree for the first time.
func _ready():	
	# Ensure we get random values
	randomize()
	
	# Running all of these will give you a [output overflow, print less text!] error
#	self.example1()
#	self.example2()
#	self.example3()
	self.example4()
#	self.example5()
#	self.example6()
	
	# Wait half a second and quit
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().quit()	
	
	
	
func example1():
	# Simple example
	var example1 = {"animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]}
	self.tracery('#animal#', example1)

func example2():
	#  Building a more complex example
	var example2 = {
	"sentence": ["The #color# #animal# of the #natureNoun# is called #name#"],
	"color": ["orange","blue","white","black","grey","purple","indigo","turquoise"],
	"animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"],
	"natureNoun": ["ocean","mountain","forest","cloud","river","tree","sky","sea","desert"],
	"name": ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"],
	}
	self.tracery('#sentence#', example2)	
	
func example3():
	# Modifiers (.a, .capitalize..)
	var example3 = {
	"sentence": ["#color.capitalize# #animal.s# are #often# #mood#.","#animal.a.capitalize# is #often# #mood#, unless it is #color.a# one."],
	"often": ["rarely","never","often","almost always","always","sometimes"],
	"color": ["orange","blue","white","black","grey","purple","indigo","turquoise"],
	"animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"],
	"mood": ["vexed","indignant","impassioned","wistful","astute","courteous"],
	"natureNoun": ["ocean","mountain","forest","cloud","river","tree","sky","earth","void","desert"],
	}
	self.tracery('#sentence#', example3)

func example4():
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

func example5():
	# Super advanced
	var example5 = {
	"name": ["Cheri","Fox","Morgana","Jedoo","Brick","Shadow","Krox","Urga","Zelph"],
	"story": ["#hero.capitalize# was a great #occupation#, and this song tells of #heroTheir# adventure. #hero.capitalize# #didStuff#, then #heroThey# #didStuff#, then #heroThey# went home to read a book."],
	"monster": ["dragon","ogre","witch","wizard","goblin","golem","giant","sphinx","warlord"],
	"setPronouns": ["[heroThey:they][heroThem:them][heroTheir:their][heroTheirs:theirs]","[heroThey:she][heroThem:her][heroTheir:her][heroTheirs:hers]","[heroThey:he][heroThem:him][heroTheir:his][heroTheirs:his]"],
	"setOccupation": ["[occupation:baker][didStuff:baked bread,decorated cupcakes,folded dough,made croissants,iced a cake]","[occupation:warrior][didStuff:fought #monster.a#,saved a village from #monster.a#,battled #monster.a#,defeated #monster.a#]"],
	"origin": ["#[#setPronouns#][#setOccupation#][hero:#name#]story#"]
	}

	var grammar5 = self.tracery('#origin#', example5)
	print("Stored values >>")
	for name in grammar5.symbols.keys():
		print("    " + name + ' = ' + grammar5.symbols[name].selected_value)

func example6():
	# Nested stories
	var example6 = {
	"name": ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"],
	"animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"],
	"occupationBase": ["wizard","witch","detective","ballerina","criminal","pirate","lumberjack","spy","doctor","scientist","captain","priest"],
	"occupationMod": ["occult ","space ","professional ","gentleman ","erotic ","time ","cyber","paleo","techno","super"],
	"strange": ["mysterious","portentous","enchanting","strange","eerie"],
	"tale": ["story","saga","tale","legend"],
	"occupation": ["#occupationMod##occupationBase#"],
	"mood": ["vexed","indignant","impassioned","wistful","astute","courteous"],
	"setPronouns": ["[heroThey:they][heroThem:them][heroTheir:their][heroTheirs:theirs]","[heroThey:she][heroThem:her][heroTheir:her][heroTheirs:hers]","[heroThey:he][heroThem:him][heroTheir:his][heroTheirs:his]"],
	"setSailForAdventure": ["set sail for adventure","left #heroTheir# home","set out for adventure","went to seek #heroTheir# forture"],
	"setCharacter": ["[#setPronouns#][hero:#name#][heroJob:#occupation#]"],
	"openBook": ["An old #occupation# told #hero# a story. 'Listen well' she said to #hero#, 'to this #strange# #tale#. ' #origin#'","#hero# went home.","#hero# found an ancient book and opened it.  As #hero# read, the book told #strange.a# #tale#: #origin#"],
	"story": ["#hero# the #heroJob# #setSailForAdventure#. #openBook#"],
	"origin": ["Once upon a time, #[#setCharacter#]story#"],
}
	var grammar6 = self.tracery('#origin#', example6)
	print("Stored values >>")
	for name in grammar6.symbols.keys():
		print("    " + name + ' = ' + grammar6.symbols[name].selected_value)

	
func tracery(entry_point, rules):
	# Run tracery
	var tracery = tracery_class.new()
	var grammar = tracery.get_grammar(rules)
	print("\n---------------- " + entry_point + " ----------------")
	print(grammar.flatten(entry_point))
	return grammar
	


