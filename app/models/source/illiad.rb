# Source::Illiad, Nostos Source Driver for Illiad
class Source::Illiad 
  attr_reader :id, :title, :due_date

  def charged?(force = false)
    if force then
      t = Illiad::Transaction.find(@id)
      @due_date = t.due_date
      @charged = t.charged?
    end

    @charged
  end

  def self.find(id)
    Illiad::Transaction.find(id).to_illiad_source
  end

  # Poll Illiad for new transactions to process. The strategy is to find
  # all transactions that have had the status Customer Notified Via E-Mail
  # within the past `number_of_days_old_transactions` days. We must join
  # the Tracking table because a transaction theoretically could go from
  # `Customer Notified Via E-Mail` to another status quicker than our
  # processing runs.
  def self.poll
    # SQL to identify records as old as 60 days
    sql = <<-SQL
      SELECT
        Tracking.TransactionNumber
      , Username
      , LoanTitle
      , LoanAuthor
      , DueDate
      , TransactionStatus
      FROM
        Tracking
        INNER JOIN Transactions ON Tracking.TransactionNumber = Transactions.TransactionNumber
      WHERE
        Tracking.ChangedTo = 'Customer Notified Via E-Mail' AND
        Tracking.DateTime > CURRENT_TIMESTAMP - #{CONFIG['number_of_days_old_transactions']} AND
        Transactions.RequestType = 'Loan'
    SQL

    Illiad::Transaction.find_by_sql(sql).map {|t| t.to_illiad_source}
  end

private
  CONFIG = YAML.load_file("#{Rails.root.to_s}/config/source_illiad.yml")[Rails.env]

  attr_reader :charged
  attr_writer :id, :title, :due_date, :charged

  def initialize(attributes = {})
    @id = attributes[:id]
    @title = attributes[:title]
    @charged = attributes[:charged]
    @due_date = attributes[:due_date]
  end

  # Extend Illiad::Transaction to map to a Source::Illiad object.
  class Illiad::Transaction
    def to_illiad_source
      Source::Illiad.new(:id => read_attribute(:TransactionNumber),
                         :title => read_attribute(:LoanTitle),
                         :due_date => read_attribute(:DueDate),
                         :charged => charged?)
    end
  end
end
