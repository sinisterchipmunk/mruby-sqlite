class TestFixture

  def initialize(label, &block)
    @fixture_label = label
    @test_count = 0
    @fail_count = 0
    @pending_count = 0
    @current_test_passed = true
    @current_test_pending = false
    puts
    puts @fixture_label
    puts '-' * label.size
    self.instance_eval(&block)
    summarize
  end

  def describe(label, &block)
    puts
    puts "  - #{label}"
    self.instance_eval(&block)
  end

  def it(label, &block)
    @current_test_passed = true
    @current_test_pending = false
    exc = nil
    begin
      self.setup if self.respond_to?(:setup)
      self.instance_eval(&block) if block
    rescue StandardError => ex
      exc = ex
      @current_test_passed = false
    end
    tag = ""
    if @current_test_pending
      tag = "[PENDING] "
    elsif !@current_test_passed
      tag = "[FAILED] "
    end
    puts "    + #{tag}#{label}"

    @test_count += 1 unless @current_test_pending
    @pending_count += 1 if @current_test_pending
    @fail_count += 1 unless @current_test_passed || @current_test_pending

    if exc && !@current_test_pending
      $stderr.puts "    Uncaught #{exc.class.to_s}: #{exc}\n#{exc.backtrace.join("\n")}"
    end
  end

  def assert(condition)
    @current_test_passed &&= condition
    condition # So client can react to result
  end
  
  def assert_nil(value)
    assert(value.nil?)
  end
  
  def assert_equal(a, b)
    result = a == b
    @current_test_passed &&= result
    result
  end
  
  def assert_instance_of(klass, obj)
    result = obj.kind_of?(klass)
    @current_test_passed &&= result
    result
  end

  def assert_raises(excClass, &block)
    begin
      block[]
    rescue excClass
      return
    rescue Exception => ex
      puts "Expected #{excClass} to be raised, but was #{ex.class}"
    else
      puts "Expected #{excClass} to be raised, but nothing was"
    end
    @current_test_passed = false
  end
  alias assert_raise assert_raises

  def fail
    @current_test_passed = false
  end

  def pending
    @current_test_pending = true
    raise "skip"
  end

  def summarize
    puts
    puts "  #{@fail_count == 0 ? 'SUCCESS' : 'FAILURE' } [#{@fail_count}/#{@test_count} tests failed + #{@pending_count} pending]"
  end
end
