require 'set'
require './3_2'

module Pattern
  def bracket(outer_precedence)
    if precedence < outer_precedence
      '(' + to_s + ')'
    else
      to_s
    end
  end

  def inspect
    "/#{self}/"
  end

  def matches?(string)
    to_nfa_design.accepts?(string)
  end
end

class Empty
  include Pattern

  def to_s
    ''
  end

  def precedence
    3
  end

  def to_nfa_design
    start_state = Object.new
    accept_states = start_state
    rulebook = NFARulebook.new([])

    NFADesign.new(Set[start_state], [accept_states], rulebook)
  end
end

class Literal < Struct.new(:character)
  include Pattern

  def to_s
    character
  end

  def precedence
    3
  end

  def to_nfa_design
    start_state = Object.new
    accept_state = Object.new
    rule = FARule.new(start_state, character, accept_state)
    rulebook = NFARulebook.new([rule])

    NFADesign.new(Set[start_state], [accept_state], rulebook)
  end
end

class Concatenate < Struct.new(:first, :second)
  include Pattern

  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence) }.join
  end

  def precedence
    1
  end

  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design

    start_state = first_nfa_design.start_states
    accept_states = second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = first_nfa_design.accept_states.flat_map{ |first_state|
      second_nfa_design.start_states.map{ |second_state|
        FARule.new(first_state, nil , second_state)
      }
    }
    rulebook = NFARulebook.new(rules + extra_rules)

    NFADesign.new(start_state, accept_states, rulebook)
  end
end

class Choose < Struct.new(:first, :second)
  include Pattern

  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence) }.join('|')
  end


  def precedence
    0
  end

  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design

    start_state = Object.new
    accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states

    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    first_extra_rules = first_nfa_design.start_states.map{ |state|
      FARule.new(start_state, nil, state)
    }
    second_extra_rules = second_nfa_design.start_states.map{ |state|
      FARule.new(start_state, nil, state)
    }
    rulebook = NFARulebook.new(rules + first_extra_rules + second_extra_rules)

    NFADesign.new(Set[start_state], accept_states, rulebook)
  end
end

class Repeat < Struct.new(:pattern)
  include Pattern

  def to_s
    pattern.bracket(precedence) + '*'
  end

  def precedence
    2
  end

  def to_nfa_design
    pattern_nfa_design = pattern.to_nfa_design

    start_state = Object.new
    accept_state = pattern_nfa_design.accept_states + [start_state]
    rules = pattern_nfa_design.rulebook.rules
    extra_rules =
        pattern_nfa_design.accept_states.flat_map { |accept_state|
          pattern_nfa_design.start_states.map{ |start_state|
            FARule.new(accept_state, nil, start_state)
          }
        } +
        pattern_nfa_design.start_states.map{ |state|
          FARule.new(start_state, nil, state)
        }
    rulebook = NFARulebook.new(rules + extra_rules)

    NFADesign.new(Set[start_state], accept_state, rulebook)
  end
end

if __FILE__ == $0
  pattern = Repeat.new(
      Choose.new(
          Concatenate.new(Literal.new('a'), Literal.new('b')),
          Literal.new('a')
      )
  )
  puts(pattern.inspect)

  nfa_design = Empty.new.to_nfa_design
  puts(nfa_design.accepts?(''))
  puts(nfa_design.accepts?('a'))
  nfa_design = Literal.new('a').to_nfa_design
  puts(nfa_design.accepts?(''))

  puts(nfa_design.accepts?('b'))

  puts(Empty.new.matches?('a')) #=> false
  puts(Literal.new('a').matches?('a')) #=> true

  pattern = Concatenate.new(
      Concatenate.new(Literal.new('a'), Literal.new('b')),
      Literal.new('c')
  )
  puts(pattern.matches?('a')) #=> false
  puts(pattern.matches?('ab')) #=> false
  puts(pattern.matches?('abc')) #=> true

  pattern = Choose.new(
                      Literal.new('a'),
                      Literal.new('b')
  )
  puts(pattern.matches?('b')) #=> true
  puts(pattern.matches?('a')) #=> true
  puts(pattern.matches?('c')) #=> false
  pattern = Repeat.new(Literal.new('a'))
  puts(pattern.matches?('')) #=> true
  puts(pattern.matches?('a')) #=> true
  puts(pattern.matches?('aaaa')) #=> true
  puts(pattern.matches?('b')) #=> false

  pattern =
      Repeat.new(
                Concatenate.new(
                               Literal.new('a'),
                               Choose.new(Empty.new, Literal.new('b'))
                )
      )
  puts(pattern.inspect)
  puts(pattern.matches?('')) #=> true
  puts(pattern.matches?('a')) #=> true
  puts(pattern.matches?('ab')) #=> true
  puts(pattern.matches?('aba')) #=> true
  puts(pattern.matches?('abab')) #=> true
  puts(pattern.matches?('abaab')) #=> true
  puts(pattern.matches?('abba')) #=> false
end

