class Stack < Struct.new(:contents)
  def push(character)
    Stack.new([character] + contents)
  end

  def pop
    Stack.new(contents.drop(1))
  end

  def top
    contents.first
  end

  def inspect
    "#<Stack (#{top})#{contents.drop(1).join}"
  end
end

class PDAConfiguration < Struct.new(:state, :stack)
end

class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_characters)
  def applies_to?(configuration, character)
    self.pop_character == configuration.stack.top && self.character == character
  end

  def follow(configuration)
    PDAConfiguration.new(next_state, next_stack(configuration))
  end

  def next_stack(configuration)
    popped_stack = configuration.stack.pop

    push_characters.reverse.inject(popped_stack) { |stack, character| stack.push(character) }
  end
end

class DPDARulebook < Struct.new(:rules)
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration)
  end

  def rule_for(configuration, character)
    rules.detect { |rule| rule.applies_to?(configuration, character) }
  end
end

class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_configuration.state)
  end

  def read_character(character)
    self.current_configuration =
        rulebook.next_configuration(current_configuration, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

if __FILE__ == $0
  stack = Stack.new(['a', 'b', 'c' ,'d', 'e'])
  puts(stack.top) #=> a
  puts(stack.pop.pop.top) #=> c
  puts(stack.push('x').push('y').top) #=> y
  puts(stack.push('x').push('y').pop.top) #=> x

  rule = PDARule.new(1, '(', 2, '$', ['b', '$'])
  puts(rule)
  configuration = PDAConfiguration.new(1, Stack.new(['$']))
  puts(configuration)
  puts(rule.applies_to?(configuration, '(')) #=> true

  puts(rule.follow(configuration))

  rulebook = DPDARulebook.new([
      PDARule.new(1, '(', 2, '$', ['b', '$']),
      PDARule.new(2, '(', 2, 'b', ['b', 'b']),
      PDARule.new(2, ')', 2, 'b', []),
      PDARule.new(2, nil, 1, '$', ['$'])
  ])
  puts(rulebook)
  configuration = rulebook.next_configuration(configuration, '(')
  puts(configuration)
  configuration = rulebook.next_configuration(configuration, '(')
  puts(configuration)
  configuration = rulebook.next_configuration(configuration, ')')
  puts(configuration)

  dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
  puts(dpda.accepting?)
  dpda.read_string('(()'); puts(dpda.accepting?)
  puts(dpda.current_configuration)
end