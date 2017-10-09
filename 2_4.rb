class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

result = Number.new(5).to_ruby()
puts(result)
result = Boolean.new(false).to_ruby()
puts(result)
proc = eval(Number.new(5).to_ruby)
result = proc.call({})
puts(result)
proc = eval(Boolean.new(false).to_ruby)
result = proc.call({})
puts(result)


class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { e[#{name.inspect}] }"
  end
end

expression = Variable.new(:x)
puts(expression)
result = expression.to_ruby()
puts(result)
proc = eval(expression.to_ruby)
result = proc.call({ x: 7})
puts(result)

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e{ (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
  end
end


class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
  end
end

result = Add.new(Variable.new(:x), Number.new(1)).to_ruby
puts(result)
result = LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby
puts(result)

environment = {x: 3}
puts(environment)
proc = eval(Add.new(Variable.new(:x), Number.new(1)).to_ruby)
result = proc.call(environment)
puts(result)

proc = eval(
    LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby
)
result = proc.call(environment)
puts(result)

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
  end
end

statement = Assign.new(:y, Add.new(Variable.new(:x), Number.new(1)))
puts(statement)
result = statement.to_ruby
puts(result)
proc = eval(statement.to_ruby)
result = proc.call({x: 3})
puts(result)

class DoNothing
  def to_ruby
    '-> e { e }'
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { if (#{condition.to_ruby}).call(e)" +
        " then (#{condition.to_ruby}).call(e)" +
        " else (#{condition.to_ruby}).call(e)" +
        " end }"
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
  end
end

class While < Struct.new(:condition, :body)
  def to_s
    "while (#{condition}) { #{body} }"
  end

  def inspect
    "<<#{self}>>"
  end

  def to_ruby
    "-> e {" +
        " while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end;" +
        " e" +
        " }"
  end
end

