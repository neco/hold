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

def mail(subject, body)
  require 'pony'

  Pony.mail(
    :to => 'holds@neco.com',
    :from => 'website@neco.com',
    :subject => subject,
    :body => body,
    :via => :smtp,
    :smtp => {
      :host => 'smtp.gmail.com',
      :port => '587',
      :user => 'website@neco.com',
      :password => '060381',
      :auth => :plain,
      :domain => 'neco.com',
      :tls => true
    }
  )
end

task :environment do
  require 'hold'
end

desc "Sync with the exchanges"
task :sync => :environment do
  begin
    Account.all.each do |account|
      account.sync
    end

    Order.all(:state => 'created').each do |order|
      begin
        order.sync
      rescue POS::TicketsNotFound
        mail('[Hold] Ticket sync failed', <<-BODY)
          Could not sync tickets for order #{order.id}.

              Event Name: #{order.event_name}
              Event: #{order.event}
              Venue: #{order.venue}
              Occurs At: #{order.occurs_at.to_s}
              Section: #{order.section}
              Row: #{order.row}
              Quantity: #{order.quantity}

          http://hold.neco.com/orders
        BODY
      end
    end

    Order.all(:state => 'synced').each do |order|
      begin
        order.hold
      rescue Order::InsufficientQuantity
        mail('[Hold] Could not place hold', <<-BODY)
          Could not hold tickets for order #{order.id}.
          A block of #{order.quantity} seats was not found.

              Event Name: #{order.event_name}
              Event: #{order.event}
              Venue: #{order.venue}
              Occurs At: #{order.occurs_at.to_s}
              Section: #{order.section}
              Row: #{order.row}
              Quantity: #{order.quantity}

          http://hold.neco.com/orders
        BODY
      end
    end
  rescue
    HoptoadNotifier.notify($!)
  end
end

namespace :db do
  desc "Automatically migrate the database"
  task :migrate => :environment do
    DataMapper.auto_upgrade!
  end
end
