require "#{::File.dirname(__FILE__)}/../../test_helper"

class TestHashClass < Test::Unit::TestCase
  context "hash_get" do
    setup do
      @hsh = {
        "10.0.0.3" => {"stuff" => "here"},
        "10.0.0.1" => {"stuff" => "here"},
        "10.0.0.2" => {"stuff" => "here"}
      }
    end
    should "should return 0.1 if we are 0.2" do
      assert @hsh.next_sorted_key("10.0.0.1"), "10.0.0.2"
      assert @hsh.next_sorted_key("10.0.0.2"), "10.0.0.3"
      assert @hsh.next_sorted_key("10.0.0.3"), "10.0.0.1"
      assert @hsh.next_sorted_key("10.0.0.1"), "10.0.0.2"
    end
    should "should return self if there is only 1 element" do
      k = {"10.0.0.2" => {"stuff" => "here"}}.next_sorted_key("10.0.0.2")
      assert k, "10.0.0.2"
    end
  end
  context "test method_missing" do
    should "should be able to call a key on the hash as a method" do
      {:first_name => "bob", :last_name => "frank"}.first_name.should == "bob"
    end
    should "should not return nil if there is no key set in the hash" do
      hsh = {:first_name => "bob", :last_name => "frank"}
      lambda {{:first_name => "bob", :last_name => "frank"}.neighbor}.should raise_error
    end
  end
  
  context "[] accessor" do
    setup do
      @mash = {:a=>'A', 'b'=>'Bob', 'nothing'=>nil}
    end
    should "returns same value with key or symbol as string" do
      assert @mash['a'] =='A'
      assert @mash[:a] == 'A'
      assert @mash[:a] == @mash['a']
      assert @mash['b'] == 'Bob'
      assert @mash[:b] == 'Bob'
      assert @mash[:b] == @mash['b']
    end
    should "return nil if key is set, and value is nil" do
      assert @mash['nothing'].nil?
      assert @mash[:nothing].nil?
    end
    should "be able to access values thru .key notation" do
      assert_equal @mash.b, 'Bob'
      assert @mash.nothing == nil
    end
  end
  
  
end