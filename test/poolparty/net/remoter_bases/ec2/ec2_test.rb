
require "#{::File.dirname(__FILE__)}/../../../../test_helper"
require "#{::File.dirname(__FILE__)}/../../../../fixtures/fake_clouds"

class Ec2Test < Test::Unit::TestCase
  
  def setup
    @cld = clouds[:app]
  end
  
  def test_basic_setup
    assert clouds.keys.include? :app
    assert_equal :ec2, clouds[:app].remoter_base
    assert_instance_of ::PoolParty::Remote::Ec2, clouds[:app].remote_base
    assert_instance_of RightAws::Ec2, clouds[:app].remote_base.ec2
  end

end