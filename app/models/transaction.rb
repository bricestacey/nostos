class Transaction < ActiveRecord::Base
  CONFIG = YAML.load_file("#{Rails.root.to_s}/config/nostos.yml")[Rails.env]

  SOURCES = CONFIG['sources'].map {|source| source.constantize}
  TARGETS = CONFIG['targets'].map {|target| target.constantize}
  MAPPING = CONFIG['mapping']

  validates_uniqueness_of :source_id, :scope => :source_type, :allow_nil => true
  validates_uniqueness_of :target_id, :scope => :target_type, :allow_nil => true

  # Retrieve this transaction's source object.
  def source
    source_type.constantize.find(source_id)
  end

  # Retrieve this transaction's target object.
  def target
    target_type.constantize.find(target_id)
  end

  # Poll each source and create a corresponding transaction if it does not exist.
  # Returns an array of source transactions that created a transaction.
  def self.poll_sources!
    r = []
    SOURCES.each do |source|
      source.poll.each do |source_t|
        # TODO: Optimize out n+1 queries to 1.
        unless Transaction.where(:source_id => source_t.id).where(:source_type => source.to_s).exists?
          if Transaction.create(:source_id => source_t.id, :source_type => source.to_s)
            r << source_t
          end
        end
      end
    end
    r
  end

  # Send transactions without a `target_id` to their target system.
  # Returns an Array of new target transactions.
  def self.send_to_targets!
    transactions = Transaction.where(:target_id => nil).all
    transactions.map do |transaction|
      target_klass = MAPPING[transaction.source_type].constantize
      t = target_klass.create(transaction.source)

      if t
        transaction.target_type = target_klass.to_s
        transaction.target_id = t.id
        transaction.save
        t
      else 
        nil
      end
    end.compact
  end

  def self.sync!
    TARGETS.each do |target|
      target.charged.each do |charged|
        transaction = Transaction.find_by_target_id(charged.id.to_s)
        if transaction
          source = transaction.source
          if source
            unless source.charged?
              puts "charging #{source}"
              source.charge!
            end
          end
        end
      end
    end
  end
end
