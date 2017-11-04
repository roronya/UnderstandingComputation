require 'set'

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end

  def follow
    next_state
  end

  def inspect
    "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}"
  end
end

class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end

  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end

  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

rulebook = NFARulebook.new([
    FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
    FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
    FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
                           ])
puts(rulebook.next_states(Set[1], 'b').inspect)
puts(rulebook.next_states(Set[1, 2], 'a').inspect)
puts(rulebook.next_states(Set[1, 3], 'b').inspect)

puts(NFA.new(Set[1], [4], rulebook).accepting?)
puts(NFA.new(Set[1, 2, 4], [4], rulebook).accepting?)

nfa = NFA.new(Set[1], [4], rulebook); puts(nfa.accepting?)
nfa.read_character('b'); puts(nfa.accepting?)
nfa.read_character('a'); puts(nfa.accepting?)
nfa.read_character('b'); puts(nfa.accepting?)
nfa = NFA.new(Set[1], [4], rulebook); puts(nfa.accepting?)
nfa.read_string('bbbbb'); puts(nfa.accepting?)

nfa_design = NFADesign.new(1, [4], rulebook)
puts(nfa_design.accepts?('bab'))
puts(nfa_design.accepts?('bbbbb'))
puts(nfa_design.accepts?('bbabb'))
