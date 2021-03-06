# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes do
  let(:model) do
    stub_model do
      include ActiveData::Model::Associations
      include ActiveData::Model::Localization

      attribute :id
      attribute :full_name
      alias_attribute :name, :full_name

      localized :t
      alias_attribute :title, :t

      embeds_one(:author) {}
      embeds_many(:projects) {}
    end
  end

  describe '.reflect_on_attribute' do
    specify { expect(model.reflect_on_attribute(:full_name).name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute('full_name').name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute(:name).name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute(:foobar)).to be_nil }
  end

  describe '.has_attribute?' do
    specify { expect(model.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.has_attribute?(:name)).to eq(true) }
    specify { expect(model.has_attribute?(:foobar)).to eq(false) }
  end

  describe '.attribute_names' do
    specify { expect(stub_model.attribute_names).to eq([])  }
    specify { expect(model.attribute_names).to eq(%w[id full_name t author projects]) }
    specify { expect(model.attribute_names(false)).to eq(%w[id full_name t])  }
  end

  describe '.inspect' do
    specify { expect(stub_model.inspect).to match(/#<Class:0x\w+>\(no attributes\)/) }
    specify { expect(stub_model(:user).inspect).to eq('User(no attributes)') }
    specify { expect(stub_model {
      include ActiveData::Model::Primary
      primary :count, type: Integer
      attribute :object
    }.inspect).to match(/#<Class:0x\w+>\(\*count: Integer, object: Object\)/) }
    specify { expect(stub_model(:user) {
      include ActiveData::Model::Primary
      primary :count, type: Integer
      attribute :object
    }.inspect).to match('User(*count: Integer, object: Object)') }
  end

  describe '#==' do
    let(:model) do
      stub_model do
        attribute :name
        attribute :count, default: 0
      end
    end
    subject { model.new name: 'hello', count: 42 }

    it { is_expected.not_to eq(nil) }
    it { is_expected.not_to eq('hello') }
    it { is_expected.not_to eq(Object.new) }
    it { is_expected.not_to eq(model.new) }
    it { is_expected.not_to eq(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eq(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eq(model.new(name: 'hello', count: 42)) }

    it { is_expected.not_to eql(nil) }
    it { is_expected.not_to eql('hello') }
    it { is_expected.not_to eql(Object.new) }
    it { is_expected.not_to eql(model.new) }
    it { is_expected.not_to eql(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eql(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eql(model.new(name: 'hello', count: 42)) }
  end

  describe '#attribute' do
    let(:instance) { model.new }
    specify { expect(instance.attribute(:full_name).reflection.name).to eq('full_name') }
    specify { expect(instance.attribute('full_name').reflection.name).to eq('full_name') }
    specify { expect(instance.attribute(:name).reflection.name).to eq('full_name') }
    specify { expect(instance.attribute(:foobar)).to be_nil }

    specify { expect(instance.attribute('full_name')).to equal(instance.attribute(:name)) }
  end

  describe '#has_attribute?' do
    specify { expect(model.new.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.new.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.new.has_attribute?(:name)).to eq(true) }
    specify { expect(model.new.has_attribute?(:foobar)).to eq(false) }
  end

  describe '#attribute_names' do
    specify { expect(stub_model.new.attribute_names).to eq([])  }
    specify { expect(model.new.attribute_names).to eq(%w[id full_name t author projects]) }
    specify { expect(model.new.attribute_names(false)).to eq(%w[id full_name t])  }
  end

  describe '#attributes' do
    specify { expect(stub_model.new.attributes).to eq({})  }
    specify { expect(model.new(name: 'Name').attributes)
      .to match({'id' => nil, 'full_name' => 'Name', 't' => {}, 'author' => nil, 'projects' => nil})  }
    specify { expect(model.new(name: 'Name').attributes(false))
      .to match({'id' => nil, 'full_name' => 'Name', 't' => {}})  }
  end

  describe '#assign_attributes' do
    let(:attributes) { { id: 42, full_name: 'Name', missed: 'value' } }
    subject { model.new }

    specify { expect { subject.assign_attributes(attributes) }.to change { subject.id }.to(42) }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.full_name }.to('Name') }
  end

  describe '#inspect' do
    specify { expect(stub_model.new.inspect).to match(/#<#<Class:0x\w+> \(no attributes\)>/) }
    specify { expect(stub_model(:user).new.inspect).to match(/#<User \(no attributes\)>/) }
    specify { expect(stub_model {
      include ActiveData::Model::Primary
      primary :count, type: Integer
      attribute :object
    }.new(object: 'String').inspect).to match(/#<#<Class:0x\w+> \*count: nil, object: "String">/) }
    specify { expect(stub_model(:user) {
      include ActiveData::Model::Primary
      primary :count, type: Integer
      attribute :object
    }.new.inspect).to match(/#<User \*count: nil, object: nil>/) }
  end

  context 'attributes integration' do
    let(:model) do
      stub_class do
        include ActiveData::Model::Attributes
        include ActiveData::Model::Associations
        attr_accessor :name

        attribute :id
        attribute :hello
        attribute :string, String, default: ->(record){ record.name }
        attribute :count, Integer, default: '10'
        attribute(:calc, Integer) { 2 + 3 }
        attribute :enum, Integer, enum: [1, 2, 3]
        attribute :enum_with_default, Integer, enum: [1, 2, 3], default: '2'
        attribute :foo, Boolean, default: false
        collection :array, enum: [1, 2, 3], default: 7

        def initialize name = nil
          super()
          @name = name
        end
      end
    end

    subject { model.new('world') }

    its(:enum_values) { should == [1, 2, 3] }
    its(:string_default) { should == 'world' }
    its(:count_default) { should == '10' }
    its(:name) { should == 'world' }
    its(:hello) { should eq(nil) }
    its(:hello?) { should eq(false) }
    its(:count) { should == 10 }
    its(:count_before_type_cast) { should == '10' }
    its(:count?) { should eq(true) }
    its(:calc) { should == 5 }
    its(:enum?) { should eq(false) }
    its(:enum_with_default?) { should eq(true) }
    specify { expect { subject.hello = 'worlds' }.to change { subject.hello }.from(nil).to('worlds') }
    specify { expect { subject.count = 20 }.to change { subject.count }.from(10).to(20) }
    specify { expect { subject.calc = 15 }.to change { subject.calc }.from(5).to(15) }

    context 'enums' do
      specify { subject.enum = 3; expect(subject.enum).to eq(3) }
      specify { subject.enum = '3'; expect(subject.enum).to eq(3) }
      specify { subject.enum = 10; expect(subject.enum).to eq(nil) }
      specify { subject.enum = 'hello'; expect(subject.enum).to eq(nil) }
      specify { subject.enum_with_default = 3; expect(subject.enum_with_default).to eq(3) }
      specify { subject.enum_with_default = 10; expect(subject.enum_with_default).to be_nil }
    end

    context 'array' do
      specify { subject.array = [2, 4]; expect(subject.array).to eq([2, nil]) }
      specify { subject.array = [2, 4]; expect(subject.array?).to eq(true) }
      specify { subject.array = [2, 4]; expect(subject.array_values).to eq([1, 2, 3]) }
      specify { subject.array = [2, 4]; expect(subject.array_default).to eq(7) }
    end

    context 'attribute caching' do
      before do
        subject.hello = 'blabla'
        subject.hello
        subject.hello = 'newnewnew'
      end

      specify { expect(subject.hello).to eq('newnewnew') }
    end
  end

  context 'inheritance' do
    let!(:ancestor) do
      Class.new do
        include ActiveData::Model::Attributes
        attribute :foo
      end
    end

    let!(:descendant1) do
      Class.new ancestor do
        attribute :bar
      end
    end

    let!(:descendant2) do
      Class.new ancestor do
        attribute :baz
        attribute :moo
      end
    end

    specify { expect(ancestor._attributes.keys).to eq(['foo']) }
    specify { expect(ancestor.instance_methods).to include :foo, :foo= }
    specify { expect(ancestor.instance_methods).not_to include :bar, :bar=, :baz, :baz= }
    specify { expect(descendant1._attributes.keys).to eq(['foo', 'bar']) }
    specify { expect(descendant1.instance_methods).to include :foo, :foo=, :bar, :bar= }
    specify { expect(descendant1.instance_methods).not_to include :baz, :baz= }
    specify { expect(descendant2._attributes.keys).to eq(['foo', 'baz', 'moo']) }
    specify { expect(descendant2.instance_methods).to include :foo, :foo=, :baz, :baz=, :moo, :moo= }
    specify { expect(descendant2.instance_methods).not_to include :bar, :bar= }
  end
end
