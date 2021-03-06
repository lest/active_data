# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsMany do
  before do
    stub_model(:dummy) do
      include ActiveData::Model::Associations
    end

    stub_model(:project) do
      include ActiveData::Model::Lifecycle

      attribute :title
      validates :title, presence: true
    end
    stub_model(:user) do
      include ActiveData::Model::Persistence
      include ActiveData::Model::Associations

      attribute :name
      embeds_many :projects
    end
  end

  let(:user) { User.new }
  let(:association) { user.association(:projects) }

  let(:existing_user) { User.instantiate name: 'Rick', projects: [{title: 'Genesis'}] }
  let(:existing_association) { existing_user.association(:projects) }

  describe 'user#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(user.association(:projects)) }
  end

  context 'performers' do
    let(:user) { User.new(projects: [Project.new(title: 'Project 1')]) }

    specify do
      p2 = user.projects.build(title: 'Project 2')
      p3 = user.projects.build(title: 'Project 3')
      p4 = user.projects.create(title: 'Project 4')
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 4'}])
      p2.save!
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 2'}, {'title' => 'Project 4'}])
      p2.destroy!.destroy!
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 4'}])
      user.projects.create(title: 'Project 5')
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 4'}, {'title' => 'Project 5'}])
      p3.destroy!
      user.projects.first.destroy!
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 4'}, {'title' => 'Project 5'}])
      p4.destroy!.save!
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 4'}, {'title' => 'Project 5'}])
      expect(user.projects.count).to eq(5)
      user.projects.map(&:save!)
      expect(user.read_attribute(:projects)).to eq([
        {'title' => 'Project 1'}, {'title' => 'Project 2'}, {'title' => 'Project 3'},
        {'title' => 'Project 4'}, {'title' => 'Project 5'}])
      user.projects.map(&:destroy!)
      expect(user.read_attribute(:projects)).to eq([])
      user.projects.first(2).map(&:save!)
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 1'}, {'title' => 'Project 2'}])
      expect(user.projects.reload.count).to eq(2)
      p3 = user.projects.create!(title: 'Project 3')
      expect(user.read_attribute(:projects)).to eq([
        {'title' => 'Project 1'}, {'title' => 'Project 2'}, {'title' => 'Project 3'}])
      p3.destroy!
      expect(user.read_attribute(:projects)).to eq([{'title' => 'Project 1'}, {'title' => 'Project 2'}])
      p4 = user.projects.create(title: 'Project 4')
      expect(user.read_attribute(:projects)).to eq([
        {'title' => 'Project 1'}, {'title' => 'Project 2'}, {'title' => 'Project 4'}])
    end
  end

  describe '#build' do
    specify { expect(association.build).to be_a Project }
    specify { expect(association.build).not_to be_persisted }

    specify { expect { association.build(title: 'Swordfish') }
      .not_to change { user.read_attribute(:projects) } }
    specify { expect { association.build(title: 'Swordfish') }
      .to change { association.reader.map(&:attributes) }
      .from([]).to([{'title' => 'Swordfish'}]) }

    specify { expect { existing_association.build(title: 'Swordfish') }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.build(title: 'Swordfish') }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]) }
  end

  describe '#create' do
    specify { expect(association.create).to be_a Project }
    specify { expect(association.create).not_to be_persisted }

    specify { expect(association.create(title: 'Swordfish')).to be_a Project }
    specify { expect(association.create(title: 'Swordfish')).to be_persisted }

    specify { expect { association.create }
      .not_to change { user.read_attribute(:projects) } }
    specify { expect { association.create(title: 'Swordfish') }
      .to change { user.read_attribute(:projects) }.from(nil).to([{'title' => 'Swordfish'}]) }
    specify { expect { association.create(title: 'Swordfish') }
      .to change { association.reader.map(&:attributes) }
      .from([]).to([{'title' => 'Swordfish'}]) }

    specify { expect { existing_association.create }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.create(title: 'Swordfish') }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{title: 'Genesis'}, {'title' => 'Swordfish'}]) }
    specify { expect { existing_association.create(title: 'Swordfish') }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]) }
  end

  describe '#create!' do
    specify { expect { association.create! }.to raise_error ActiveData::ValidationError }

    specify { expect(association.create!(title: 'Swordfish')).to be_a Project }
    specify { expect(association.create!(title: 'Swordfish')).to be_persisted }

    specify { expect { association.create! rescue nil }
      .not_to change { user.read_attribute(:projects) } }
    specify { expect { association.create! rescue nil }
      .to change { association.reader.map(&:attributes) }.from([]).to([{'title' => nil}]) }
    specify { expect { association.create!(title: 'Swordfish') }
      .to change { user.read_attribute(:projects) }.from(nil).to([{'title' => 'Swordfish'}]) }
    specify { expect { association.create!(title: 'Swordfish') }
      .to change { association.reader.map(&:attributes) }
      .from([]).to([{'title' => 'Swordfish'}]) }

    specify { expect { existing_association.create! rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.create! rescue nil }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => nil}]) }
    specify { expect { existing_association.create!(title: 'Swordfish') }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{title: 'Genesis'}, {'title' => 'Swordfish'}]) }
    specify { expect { existing_association.create!(title: 'Swordfish') }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]) }
  end

  describe '#save' do
    specify { expect { association.build; association.save }.to change { association.target.map(&:persisted?) }.to([false]) }
    specify { expect { association.build(title: 'Genesis'); association.save }.to change { association.target.map(&:persisted?) }.to([true]) }
    specify { expect {
      existing_association.target.first.mark_for_destruction
      existing_association.build(title: 'Swordfish');
      existing_association.save
    }.to change { existing_association.target.map(&:destroyed?) }.to([true, false]) }
    specify { expect {
      existing_association.target.first.mark_for_destruction
      existing_association.build(title: 'Swordfish');
      existing_association.save
    }.to change { existing_association.target.map(&:persisted?) }.to([false, true]) }
  end

  describe '#save!' do
    specify { expect { association.build; association.save! }.to raise_error ActiveData::AssociationNotSaved }
    specify { expect { association.build(title: 'Genesis'); association.save! }.to change { association.target.map(&:persisted?) }.to([true]) }
    specify { expect {
      existing_association.target.first.mark_for_destruction
      existing_association.build(title: 'Swordfish');
      existing_association.save!
    }.to change { existing_association.target.map(&:destroyed?) }.to([true, false]) }
    specify { expect {
      existing_association.target.first.mark_for_destruction
      existing_association.build(title: 'Swordfish');
      existing_association.save!
    }.to change { existing_association.target.map(&:persisted?) }.to([false, true]) }
  end

  describe '#target' do
    specify { expect(association.target).to eq([]) }
    specify { expect(existing_association.target).to eq(existing_user.projects) }
    specify { expect { association.build }.to change { association.target.count }.to(1) }
  end

  describe '#default' do
    before { User.embeds_many :projects, default: -> { { title: 'Default' } } }
    let(:new_project) { Project.new(title: 'Project') }
    let(:existing_user) { User.instantiate name: 'Rick' }

    specify { expect(association.target.map(&:title)).to eq(['Default']) }
    specify { expect(association.target.map(&:new_record?)).to eq([true]) }
    specify { expect { association.replace([new_project]) }.to change { association.target.map(&:title) }.to eq(['Project']) }
    specify { expect { association.replace([]) }.to change { association.target }.to([]) }

    specify { expect(existing_association.target).to eq([]) }
    specify { expect { existing_association.replace([new_project]) }.to change { existing_association.target.map(&:title) }.to(['Project']) }
    specify { expect { existing_association.replace([]) }.not_to change { existing_association.target } }
  end

  describe '#loaded?' do
    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.build }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace([]) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace([]) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { expect(association.reload).to eq([]) }

    specify { expect(existing_association.reload).to eq(existing_user.projects) }

    context do
      before { association.build(title: 'Swordfish') }
      specify { expect { association.reload }
        .to change { association.reader.map(&:attributes) }.from([{'title' => 'Swordfish'}]).to([]) }
    end

    context do
      before { existing_association.build(title: 'Swordfish') }
      specify { expect { existing_association.reload }
        .to change { existing_association.reader.map(&:attributes) }
        .from([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]).to([{'title' => 'Genesis'}]) }
    end
  end

  describe '#clear' do
    specify { expect(association.clear).to eq(true) }
    specify { expect { association.clear }.not_to change { association.reader } }

    specify { expect(existing_association.clear).to eq(true) }
    specify { expect { existing_association.clear }
      .to change { existing_association.reader.map(&:attributes) }.from([{'title' => 'Genesis'}]).to([]) }
    specify { expect { existing_association.clear }
      .to change { existing_user.read_attribute(:projects) }.from([{title: 'Genesis'}]).to([]) }

    context do
      let(:existing_user) { User.instantiate name: 'Rick', projects: [{title: 'Genesis'}, {title: 'Swordfish'}] }
      before { Project.send(:include, ActiveData::Model::Callbacks) }
      before { Project.before_destroy { title == 'Genesis' } }

      specify { expect(existing_association.clear).to eq(false) }
      specify { expect { existing_association.clear }
        .not_to change { existing_association.reader } }
      specify { expect { existing_association.clear }
        .not_to change { existing_user.read_attribute(:projects) } }
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to eq([]) }

    specify { expect(existing_association.reader.first).to be_a Project }
    specify { expect(existing_association.reader.first).to be_persisted }

    context do
      before { association.build }
      specify { expect(association.reader.last).to be_a Project }
      specify { expect(association.reader.last).not_to be_persisted }
      specify { expect(association.reader.size).to eq(1) }
      specify { expect(association.reader(true)).to eq([]) }
    end

    context do
      before { existing_association.build(title: 'Swordfish') }
      specify { expect(existing_association.reader.size).to eq(2) }
      specify { expect(existing_association.reader.last.title).to eq('Swordfish') }
      specify { expect(existing_association.reader(true).size).to eq(1) }
      specify { expect(existing_association.reader(true).last.title).to eq('Genesis') }
    end
  end

  describe '#writer' do
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }
    let(:invalid_project) { Project.new }

    specify { expect { association.writer([Dummy.new]) }
      .to raise_error ActiveData::AssociationTypeMismatch }

    specify { expect { association.writer(nil) }.to raise_error NoMethodError }
    specify { expect { association.writer(new_project1) }.to raise_error NoMethodError }
    specify { expect(association.writer([])).to eq([]) }

    specify { expect(association.writer([new_project1])).to eq([new_project1]) }
    specify { expect { association.writer([new_project1]) }
      .to change { association.reader.map(&:attributes) }.from([]).to([{'title' => 'Project 1'}]) }
    specify { expect { association.writer([new_project1]) }
      .not_to change { user.read_attribute(:projects) } }

    specify { expect { existing_association.writer([new_project1, invalid_project]) }
      .to raise_error ActiveData::AssociationNotSaved }
    specify { expect { existing_association.writer([new_project1, invalid_project]) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.writer([new_project1, invalid_project]) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect { existing_association.writer([new_project1, Dummy.new, new_project2]) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { existing_association.writer([new_project1, Dummy.new, new_project2]) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.writer([new_project1, Dummy.new, new_project2]) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect { existing_association.writer(nil) }.to raise_error NoMethodError }
    specify { expect { existing_association.writer(nil) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.writer(nil) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect(existing_association.writer([])).to eq([]) }
    specify { expect { existing_association.writer([]) }
      .to change { existing_user.read_attribute(:projects) }.to([]) }
    specify { expect { existing_association.writer([]) }
      .to change { existing_association.reader }.to([]) }

    specify { expect(existing_association.writer([new_project1, new_project2])).to eq([new_project1, new_project2]) }
    specify { expect { existing_association.writer([new_project1, new_project2]) }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
    specify { expect { existing_association.writer([new_project1, new_project2]) }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
  end

  describe '#concat' do
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }
    let(:invalid_project) { Project.new }

    specify { expect { association.concat(Dummy.new) }
      .to raise_error ActiveData::AssociationTypeMismatch }

    specify { expect { association.concat(nil) }.to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect(association.concat([])).to eq([]) }
    specify { expect(existing_association.concat([])).to eq(existing_user.projects) }
    specify { expect(existing_association.concat).to eq(existing_user.projects) }

    specify { expect(association.concat(new_project1)).to eq([new_project1]) }
    specify { expect { association.concat(new_project1) }
      .to change { association.reader.map(&:attributes) }.from([]).to([{'title' => 'Project 1'}]) }
    specify { expect { association.concat(new_project1) }
      .not_to change { user.read_attribute(:projects) } }

    specify { expect(existing_association.concat(new_project1, invalid_project)).to eq(false) }
    specify { expect { existing_association.concat(new_project1, invalid_project) }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}]) }
    specify { expect { existing_association.concat(new_project1, invalid_project) }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}, {'title' => nil}]) }

    specify { expect { existing_association.concat(new_project1, Dummy.new, new_project2) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { existing_association.concat(new_project1, Dummy.new, new_project2) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.concat(new_project1, Dummy.new, new_project2) rescue nil }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}]) }

    specify { expect(existing_association.concat(new_project1, new_project2))
      .to eq([existing_user.projects.first, new_project1, new_project2]) }
    specify { expect { existing_association.concat([new_project1, new_project2]) }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
    specify { expect { existing_association.concat([new_project1, new_project2]) }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
  end
end
