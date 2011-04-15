namespace :nostos do
  task :poll_sources => :environment do 
    Transaction.poll_sources!
  end

  task :send_to_targets => :environment do
    Transaction.send_to_targets!
  end

  task :cron => :environment do
    Transaction.poll_sources!
    Transaction.send_to_targets!
    Transaction.sync!
  end
end
