require 'spec_helper'

describe ActiveData::Model::Primary do
  context 'undefined' do
    let(:model) do
      stub_model do
        include ActiveData::Model::Primary

        attribute :name
      end
    end

    specify { expect(model.has_primary_attribute?).to eq(false) }
    specify { expect(model.new.has_primary_attribute?).to eq(false) }
    specify { expect { model.new.primary_attribute }.to raise_error NoMethodError }
    specify { expect(model.new(name: 'Hello')).to eq(model.new(name: 'Hello')) }
    specify { expect(model.new(name: 'Hello')).to eql(model.new(name: 'Hello')) }

    context do
      let(:object) { model.new(name: 'Hello') }
      specify { expect(object).not_to eq(object.clone.tap { |o| o.update(name: 'World') }) }
      specify { expect(object).not_to eql(object.clone.tap { |o| o.update(name: 'World') }) }
    end
  end

  context 'defined' do
    let(:model) do
      stub_model do
        include ActiveData::Model::Primary

        primary_attribute
        attribute :name
      end
    end

    specify { expect(model.has_primary_attribute?).to eq(true) }
    specify { expect(model.new.has_primary_attribute?).to eq(true) }
    specify { expect(model.new.primary_attribute).to be_a(ActiveData::UUID) }
    specify { expect(model.new(name: 'Hello')).not_to eq(model.new(name: 'Hello')) }
    specify { expect(model.new(name: 'Hello')).not_to eql(model.new(name: 'Hello')) }
    specify { expect(model.new(id: 0).id).not_to eq(ActiveData::UUID.parse_int(0)) }
    specify { expect(model.new.tap { |o| o.id = 0 }.id).to eq(ActiveData::UUID.parse_int(0)) }

    context do
      let(:object) { model.new(name: 'Hello') }
      specify { expect(object).to eq(object.clone.tap { |o| o.update(name: 'World') }) }
      specify { expect(object).to eql(object.clone.tap { |o| o.update(name: 'World') }) }
    end
  end

  context 'defined' do
    let(:model) do
      stub_model do
        include ActiveData::Model::Primary

        primary_attribute type: Integer
        attribute :name
      end
    end

    specify { expect(model.has_primary_attribute?).to eq(true) }
    specify { expect(model.new.has_primary_attribute?).to eq(true) }
    specify { expect(model.new.primary_attribute).to be_nil }
    specify { expect(model.new(name: 'Hello')).not_to eq(model.new(name: 'Hello')) }
    specify { expect(model.new(name: 'Hello')).not_to eql(model.new(name: 'Hello')) }
    specify { expect(model.new(name: 'Hello').tap { |o| o.id = 1 }).not_to eq(model.new(name: 'Hello').tap { |o| o.id = 2 }) }
    specify { expect(model.new(name: 'Hello').tap { |o| o.id = 1 }).not_to eql(model.new(name: 'Hello').tap { |o| o.id = 2 }) }
    specify { expect(model.new(id: 1).id).to be_nil }
    specify { expect(model.new.tap { |o| o.id = 1 }.id).to eq(1) }

    context do
      let(:object) { model.new(name: 'Hello').tap { |o| o.id = 1 } }
      specify { expect(object).to eq(object.clone.tap { |o| o.update(name: 'World') }) }
      specify { expect(object).to eql(object.clone.tap { |o| o.update(name: 'World') }) }
    end

    context do
      let(:object) { model.new(name: 'Hello') }
      specify { expect(object).to eq(object) }
      specify { expect(object).to eql(object) }
    end
  end
end
