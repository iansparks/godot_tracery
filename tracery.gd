class_name Tracery

func get_grammar(input_rules:Dictionary):
	var grammar = tGrammar.new(input_rules)
	return grammar

class tGrammar:

	var rules = {}
	var errors = []
	var modifiers = {}
	var symbols = {}
	var subgrammars:Array = []
	
	func _init(rules:Dictionary):		
		self.rules = rules
		
		# Load default rules
		self.modifiers = tModifiers.base_english()
		self.errors = []
		self.symbols = {}
		self.subgrammars = []
		
		# Load symbolds from the passed in rules
		for k in rules.keys():
			self.symbols[k] = tSymbol.new(self, k, rules[k])
	
	func flatten(rule:String, allow_escape_chars:bool = false):
		var root = self.expand(rule, allow_escape_chars)
		return root.finished_text	
		
	func create_root(rule):
		return tNode.new(self, 0, {'type': -1, 'raw': rule})
		
	func expand(rule:String, allow_escape_chars:bool):
		var root = self.create_root(rule)
		root.expand()
		if not allow_escape_chars:
			root.clear_escape_chars()
		Utils.extend_array(self.errors, root.errors)
		return root
	
	func push_rules(key:String, raw_rules):
		if !(key in self.symbols):
			self.symbols[key] = tSymbol.new(self, key, raw_rules)
		else:
			self.symbols[key].push_rules(raw_rules)
		
	func pop_rules(key:String):
		if !(key in self.symbols):
			self.errors.append("Can't pop: no symbol for key " + key)
		else:
			self.symbols[key].pop_rules()
			
	func select_rule(key:String, node:tNode, errors:Array):
		if key in self.symbols:
			return self.symbols[key].select_rule(node, errors)
		else:
			if key == null:
				key = "null"
			self.errors.append("No symbol for " + key)
		return "((" + key + "))"
	
# Utilities
class Utils:
	static func extend_array(array:Array, with_elements:Array):
		# Extend an array with a set of elements
		for element in with_elements:
			array.append(element)
	
	static func slice_string(input_string:String, start:int, end:int):
		var return_string = ""
		if end == -1:
			end = input_string.length()
			
		for i in range(0, input_string.length()):
			if i>= start and i <= end-1:
				return_string += input_string[i]
				
		return return_string
	
	static func slice_array(input_array:Array, start:int, end:int):
		var return_array = []
		
		if end == -1:
			end = input_array.size()
		
		for i in range(0, input_array.size()):
			if i >= start and i <= end:
				return_array.append(input_array[i]) 
		
		return return_array
		
	static func parse_tag(tag_contents):
		# returns a dictionary with 'symbol', 'modifiers', 'preactions', 'postactions'
		var parsed = {
			"symbol" : null,
			"preactions" : [],
			"postactions" : [],
			"modifiers" : [] 
		}
		var parse_result = Utils.parse(tag_contents)
		var sections = parse_result.sections
		#var errors = parse_result.errors
		
		var symbol_section = null
		for section in sections:
			if section['type'] == 0:
				if symbol_section == null:
					symbol_section = section['raw']
				else:
					# Exception
					print("EXCEPTION! multiple main sections in " + tag_contents)

			else:
				parsed['preactions'].append(section)
		if symbol_section != null:
			var components = symbol_section.split(".")
			parsed.symbol = components[0]
			parsed.modifiers = Utils.slice_array(components, 1,-1)
		return parsed
		
	static func create_section(start, end, type, errors, rule, last_escaped_char, escaped_substring):
		if end - start < 1:
			if type == 1:
				errors.append("{}:empty tag".format(start))
			elif type == 2:
				errors.append("{}:empty action".format(start))
		var raw_substring = null
		if last_escaped_char != null:
			raw_substring = escaped_substring + "\\" + slice_string(rule, last_escaped_char+1, end)
		else:
			raw_substring = slice_string(rule, start, end)
		var ret = {'type': type, 'raw': raw_substring}
		return ret
		
	static func parse(rule:String) -> Dictionary:
		var depth = 0
		var in_tag = false
		var sections = []
		var escaped = false
		var errors = []
		var start = 0
		var escaped_substring = ""
		var last_escaped_char = null

		if rule == null:
			return sections
		
		for i in range(0, rule.length()):
			var c = rule[i]
			if !escaped:
				if c == '[':
					if depth == 0 and !in_tag:
						if start < i:
							var s = Utils.create_section(start, i, 0, errors, rule, last_escaped_char, escaped_substring)
							sections.append(s)
							last_escaped_char = null
							escaped_substring = ""
						start = i + 1
					depth += 1
				elif c == ']':
					depth -= 1
					if depth == 0 and !in_tag:
						var s = Utils.create_section(start, i, 2, errors, rule, last_escaped_char, escaped_substring)
						sections.append(s)
						last_escaped_char = null
						escaped_substring = ""
						start = i + 1
				elif c == '#':
					if depth == 0:
						if in_tag:
							var s = Utils.create_section(start, i, 1, errors, rule, last_escaped_char, escaped_substring)
							sections.append(s)
							last_escaped_char = null
							escaped_substring = ""
						else:
							if start < i:
								var s = Utils.create_section(start, i, 0, errors, rule, last_escaped_char, escaped_substring)
								sections.append(s)
								last_escaped_char = null
								escaped_substring = ""
						start = i + 1
						in_tag = !in_tag
				elif c == '\\':
					escaped = true
					escaped_substring = escaped_substring + slice_string(rule, start, i)
					start = i + 1
					last_escaped_char = i
			else:
				escaped = false
			
		if start < rule.length():
			var s = Utils.create_section(start, rule.length(), 0, errors, rule, last_escaped_char, escaped_substring)
			sections.append(s)
			last_escaped_char = null
			escaped_substring = ""
	
		if in_tag:
			errors.append("unclosed tag")
		if depth > 0:
			errors.append("too many [")
		if depth < 0:
			errors.append("too many ]")
		
		# Filter sections to remove those of type 0 and length 0		
		var return_sections = []
		for s in sections:
			if !(s.type == 0 and s.raw.length() == 0):
				return_sections.append(s)
				
		return {'sections':return_sections, 'errors':errors}
		
class tNode:
	var action = null
	var parent = null
	var errors:Array = []
	var preactions:Array = []
	var postactions:Array = []
	var expansion_errors:Array = []
	var is_expanded:bool = false
	var children:Array = []
	var child_rule:String
	var raw:String = ''
	var type = null
	var grammar = null
	var depth = 0
	var child_index = 0
	var symbol
	var modifiers
	var finished_text:String = ""
	
	func _init(_parent, child_index:int, settings:Dictionary ):
		self.parent = _parent
		if settings.get('raw') == null:
			self.errors.append("Empty input for node")
			settings.raw = ""
		if parent is tGrammar:
			self.grammar = parent
			self.parent = null
			self.depth = 0
			self.child_index = 0
		else:
			self.grammar = parent.grammar
			self.parent = parent
			self.depth = parent.depth + 1
			self.child_index = child_index
		self.raw = settings['raw']
		self.type = settings.get('type', null)
		self.is_expanded = false
	
	func expand_tag(prevent_recursion):
		self.preactions = []
		self.postactions = []
		var parsed = Utils.parse_tag(self.raw)
		self.symbol = parsed['symbol']
		self.modifiers = parsed['modifiers']
		for preaction in parsed['preactions']:
			var node_action = tNodeAction.new(self, preaction['raw'])
			self.preactions.append(node_action)
		for preaction in self.preactions:
			if preaction.type == 0:
				self.postactions.append(preaction.create_undo())
		for preaction in self.preactions:
			preaction.activate()
			
		self.finished_text = self.raw
		var selected_rule = self.grammar.select_rule(self.symbol, self, self.errors)
		self.expand_children(selected_rule, prevent_recursion)

		# apply modifiers (capitalization, pluralization etc)
		for mod_name in self.modifiers:
			var mod_params = []
			if '(' in mod_name:
				var regex = RegEx.new()
				# Invalid regex - fix me later
				var regexp = regex.compile('[^]+')
				var matches = regexp.search_all(mod_name)
				if len(matches) > 0:
					mod_params = matches[0].split(",")
					mod_name = mod_name.substr(0, mod_name.find('('))
					
			var mod:FuncRef = self.grammar.modifiers.get(mod_name, null)
			if mod == null:
				self.errors.append("Missing modifier " + mod_name)
				self.finished_text += "((." + mod_name + "))"
			else:
				var value = mod.call_func(self.finished_text, mod_params)
				self.finished_text = value
				
	func expand(prevent_recursion=false):
		if !self.is_expanded:
			self.is_expanded = true
			self.expansion_errors = []
			# Types of nodes
			# -1: raw, needs parsing
			#  0: Plaintext
			#  1: Tag ("#symbol.mod.mod2.mod3#" or
			#     "#[pushTarget:pushRule]symbol.mod")
			#  2: Action ("[pushTarget:pushRule], [pushTarget:POP]",
			#     more in the future)
			match self.type:
				-1:
					self.expand_children(self.raw, prevent_recursion)
				0:
					self.finished_text = self.raw
				1:
					self.expand_tag(prevent_recursion)
				2:
					self.action = tNodeAction.new(self, self.raw)
					self.action.activate()
					self.finished_text = ""
					
					
	func expand_children(child_rule, prevent_recursion=false):
		self.children = []
		self.finished_text = ""
		
		self.child_rule = child_rule
		if self.child_rule != null:
			var parse_result = Utils.parse(child_rule)
			for error in parse_result.errors:
				self.errors.append(errors)
			for i in range(0, parse_result.sections.size()):
				var section = parse_result.sections[i]
				var node = tNode.new(self, i, section)
				self.children.append(node)
				if !prevent_recursion:
					node.expand(prevent_recursion)
				self.finished_text += node.finished_text
		else:
			self.errors.append("No child rule provided, can't expand children")
					
	func clear_escape_chars():
		self.finished_text = self.finished_text.replace("\\\\", "DOUBLEBACKSLASH").replace("\\", "").replace("DOUBLEBACKSLASH", "\\")
		
		
		
class tNodeAction:

	var node = null
	var target
	var rule:String
	var rule_sections:Array
	var rule_nodes:Array
	var finished_rules:Array
	var type
	
	func _init(node:tNode, raw:String):
		self.node = node
		var sections = raw.split(':')
		self.target = sections[0]
		if sections.size() == 1:
			self.type = 2
		else:
			self.rule = sections[1]
			if self.rule == "POP":
				self.type = 1
			else:
				self.type = 0
				
	func create_undo():
		if self.type == 0:
			var na = tNodeAction.new(self.node, self.target + ":POP")
			return na
		return null

	func activate():
		var grammar = self.node.grammar
		if self.type == 0:
			self.rule_sections = self.rule.split(",")
			self.finished_rules = []
			self.rule_nodes = []
			for rule_section in self.rule_sections:
				var n = tNode.new(grammar, 0, {'type': -1, 'raw': rule_section})
				n.expand()
				self.finished_rules.append(n.finished_text)
			grammar.push_rules(self.target, self.finished_rules)
		elif self.type == 1:
			grammar.pop_rules(self.target)
		elif self.type == 2:
			grammar.flatten(self.target, true)
			
			
class tSymbol:

	var grammar:tGrammar
	var key:String
	
	# The value that gets selected for this symbol
	var selected_value:String
	# Stack is an array of tRuleSet
	var stack:Array = []
	var raw_rules
	var uses:Array = []
	var base_rules:tRuleSet
	
	
	func _init(grammar:tGrammar, key:String, raw_rules):
		self.grammar = grammar
		self.key = key
		self.raw_rules = raw_rules
		self.base_rules = tRuleSet.new(grammar, raw_rules)
		self.clear_state()
		
	func clear_state():
		self.stack = [self.base_rules]
		self.uses = []
		self.base_rules.clear_state()

	func push_rules(raw_rules):
		var rules = tRuleSet.new(self.grammar, raw_rules)
		self.stack.append(rules)

	func pop_rules():
		self.stack.pop_back()

	func select_rule(node, errors):
		self.uses.append({'node': node})
		if self.stack.size() == 0:
			errors.append("The rule stack for '%s' is empty, too many pops?" % self.key)
		self.selected_value = self.stack.back().select_rule()
		return self.selected_value

#	func get_active_rules():
#		if self.stack.size() == 0:
#			return null
#		return self.stack.back().select_rule()


class tRuleSet:
	
	var raw
	var grammar:tGrammar
	var default_uses:Array = []
	var default_rules:Array = []
	
	func _init(grammar, raw):
		self.raw = raw
		self.grammar = grammar
		self.default_uses = []
		if raw is Array:
			self.default_rules = raw
		elif raw is String:
			self.default_rules = [raw]
		else:
			self.default_rules = []
			
	func clear_state():
		self.default_uses = []
		
	func select_rule():
		# The method for selecting a rule is just to take a random one. 
		# This makes it easy to deal with arrays that come from JSON 
		# but you could have more complex rules like removing an option from the
		# array once it's been used or has been used N times and having weightings on
		# the entries. You could use self.grammer and pass the rules into the grammar
		return self.default_rules[randi() % self.default_rules.size()]
		
		
class tModifiers:
	
	const VOWELS:Array = ["a","e","i","o","u"]
	
	static func replace(text:String, params_list:Array) -> String:
		return text.replace(params_list[0], params_list[1])
		
	static func capitalizeAll(text:String, params_list:Array) -> String:
		return text.capitalize()
		
	static func capitalize(text:String, params_list:Array) -> String:
		var first = text[0]
		var rest = text.right(1)
		return first.to_upper() + rest
		
	static func a(text:String, params_list:Array) -> String:
		if text.length() > 0:
			if text[0].to_lower() == "u":
				if text.length() > 2:
					if text[2].to_lower() == "i":
						return "a " + text
			if text[0].to_lower() in VOWELS:
				return "an " + text
		return "a " + text
		
	static func firstS(text:String, params_list:Array) -> String:
		var return_string:String = ""
		var text2 = text.split(" ")
		
		return_string = tModifiers.s(text2[0], [])
		return_string += text2.right(1)
		return return_string
		
	static func s(text:String, params_list:Array) -> String:
		var last_char = text[text.length()-1].to_lower()
		if last_char in ["s","h","x"]:
			return text + "es"
		elif last_char == "y":
			var last_but_one_char = text[text.length()-2].to_lower()
			if !(last_but_one_char in VOWELS):
				return text.substr(0, text.length()-2)  + "ies"
			else:
				return text + "s"
		return text + "s"
			
	static func ed(text:String, params_list:Array) -> String:
		var last_char = text[text.length()-1].to_lower()
		if last_char == "e":
			return text + "d"
		elif last_char == "y":
			var last_but_one_char = text[text.length()-2].to_lower()
			if !(last_but_one_char in VOWELS):
			 	return text.substr(0, text.length()-2)  + "ied"
		return text + "ed"
		
	static func uppercase(text:String, params_list:Array) -> String:
		return text.to_upper()

	static func lowercase(text:String, params_list:Array) -> String:
		return text.to_lower()

	static func base_english() -> Dictionary:
		# Get dictionary of function references to our modifier functions
		return {
		    'replace': funcref(tModifiers, "replace"),
		    'capitalizeAll': funcref(tModifiers, "capitalizeAll"),
		    'capitalize': funcref(tModifiers, "capitalize"),
		    'a': funcref(tModifiers, "a"),
		    'firstS': funcref(tModifiers, "firstS"),
		    's': funcref(tModifiers, "s"),
		    'ed': funcref(tModifiers, "ed"),
		    'uppercase': funcref(tModifiers, "uppercase"),
		    'lowercase': funcref(tModifiers, "lowercase")
		}