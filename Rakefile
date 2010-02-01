require 'rake'
require 'spec/rake/spectask'

task :default => :spec

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :environment do
  require 'hold'
end

desc "Sync with the exchanges"
task :sync => :environment do
  Account.all.each do |account|
    account.sync
  end

  Order.all(:state => 'created').each do |order|
    order.sync
  end
end

namespace :db do
  desc "Automatically migrate the database"
  task :migrate => :environment do
    DataMapper.auto_upgrade!
  end
end
