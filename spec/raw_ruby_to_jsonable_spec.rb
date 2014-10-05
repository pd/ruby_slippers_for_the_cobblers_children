require 'app'

RSpec.describe RawRubyToJsonable do
  # I don't know what I want yet, just playing to see

  def call(raw_code)
    json = RawRubyToJsonable.call raw_code
    assert_valid json
    json
  end

  def assert_valid(json)
    case json
    when String, Fixnum, nil
      # no op
    when Array
      json.each { |element| assert_valid element }
    when Hash
      json.each do |k, v|
        raise unless k.kind_of? String
        assert_valid v
      end
    else
      raise "#{json.inspect} does not appear to be a JSON type"
    end
  end

  context 'single and multiple expressions' do
    example 'single expression is just the expression type' do
      result = call '1'
      expect(result['type']).to eq 'integer'
      expect(result['highlightings']).to eq [[0, 1]]
      expect(result['value']).to eq 1
    end

    example 'multiple expressions, no bookends, newline delimited' do
      result = call "9\n8"
      expect(result['type']).to eq 'expressions'
      expect(result['highlightings']).to eq [[0, 3]]

      expr1, expr2, *rest = result['children']
      expect(rest).to be_empty

      expect(expr1['type']).to eq 'integer'
      expect(expr1['highlightings']).to eq [[0, 1]]
      expect(expr1['value']).to eq 9

      expect(expr2['type']).to eq 'integer'
      expect(expr2['highlightings']).to eq [[2, 3]]
      expect(expr2['value']).to eq 8
    end

    example 'multiple expressions, parentheses bookends, newline delimited' do
      result = call "(9\n8)"
      expect(result['type']).to eq 'expressions'
      expect(result['highlightings']).to eq [[0, 5]]
      expect(result['children'].size).to eq 2
    end

    example 'multiple expressions, begin/end bookends, newline delimited' do
      result = call "begin\n 1\nend"
      expect(result['type']).to eq 'keyword_begin'
      expect(result['highlightings']).to eq [[0, 5], [9, 12]]
      expr, *rest = result['children']
      expect(rest).to be_empty
      expect(expr['type']).to eq 'integer'
      expect(expr['highlightings']).to eq [[7, 8]]
      expect(expr['value']).to eq 1
    end

    example 'semicolon delimited' do
      result = call "1;2"
      expect(result['type']).to eq 'expressions'
      expect(result['highlightings']).to eq [[0, 3]]
      expect(result['children'].size).to eq 2

      result = call "(1;2)"
      expect(result['type']).to eq 'expressions'
      expect(result['children'].size).to eq 2

      result = call "begin;1;end"
      expect(result['type']).to eq 'keyword_begin'
      expect(result['children'].size).to eq 1
    end
  end

  'set and get local variable'
  'integer literals'
  'symbol literals' # type/highlightings/value
  'class definitions'
  'module definitions'
  # idk, look at SiB for a start

  context 'send', t:true do
    example 'with no receiver' do
      result = call 'load'
      expect(result['type']).to eq 'send'
      expect(result['highlightings']).to eq [[0, 4]]
      expect(result['target']).to eq nil
      expect(result['message']).to eq 'load'
      expect(result['args']).to be_empty
    end

    example 'without args' do
      result = call '1.even?'
      expect(result['type']).to eq 'send'
      expect(result['highlightings']).to eq [[0, 7]]

      expect(result['target']['value']).to eq 1
      expect(result['message']).to eq 'even?'
      expect(result['args']).to be_empty
    end

    example 'with args' do
      result = call '1.a 2, 3'
      expect(result['type']).to eq 'send'
      expect(result['highlightings']).to eq [[0, 8]]

      expect(result['target']['value']).to eq 1
      expect(result['message']).to eq 'a'
      expect(result['args'].map { |a| a['value'] }).to eq [2, 3]
    end

    example 'with operator' do
      result = call '1 % 2'
      expect(result['type']).to eq 'send'
      expect(result['highlightings']).to eq [[0, 5]]

      expect(result['target']['value']).to eq 1
      expect(result['message']).to eq '%'
      expect(result['args'].map { |a| a['value'] }).to eq [2]
    end
  end
end