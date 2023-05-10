# A quick and dirty [TAP][] runner.
#
# [TAP]: http://testanything.org/
class TAP
  def initialize
    @tests = []
  end

  # Declare a test to be run by {#run}. A failing test raises.
  def test(description, &body)
    @tests << [description, body]
  end

  def run_one(i, description, &body)
    puts
    puts "# Beginning #{i} #{description}"
    body.call
    puts "ok #{i} #{description}"
  rescue => e
    puts "# Exception: #{e}"
    puts "not ok #{i} #{description}"
  end

  def run
    # test plan
    puts "1..#{@tests.size}"
    @tests.each_with_index do |item, i|
      description, body = item
      run_one(i + 1, description, &body)
    end
  end
end
