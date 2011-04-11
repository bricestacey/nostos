class Target::Voyager 
  CONFIG = YAML.load_file("#{Rails.root.to_s}/config/target_voyager.yml")[Rails.env]

  attr_reader :id, :title, :due_date

  def charged?(force = false)
    if force then
      r = Target::Voyager.find(@id)
      @charged = r.charged
      @due_date = r.due_date
    end

    @charged
  end


  # Target Interface
  def self.find(id)
    id = id.to_s unless id.is_a?(String)

    Voyager::SipClient.new(CONFIG['sip']['host'], CONFIG['sip']['port']) do |sip|
      sip.login(CONFIG['sip']['username'], CONFIG['sip']['password'], CONFIG['sip']['location']) do |response|
        if response[:ok] != '1' # Login failed
          Rails::logger.error "Failed to sign in to SIP server"
          return false
        end

        if response[:ok] == '1' # Login successful
          sip.item_status(id) do |item_status|
            return nil unless item_status[:AF] == 'Item Info retrieved successfully.'

            if item_status[:circ_status] == '04' || item_status[:circ_status] == '05'
              target = Target::Voyager.new(:id => id, :title => item_status[:AJ], :charged => true, :due_date => item_status[:AH])
            else
              target = Target::Voyager.new(:id => id, :title => item_status[:AJ], :charged => false, :due_date => nil)
            end

            return target
          end
        end
      end
    end

    nil
  end

  def self.create(item = {})
    return nil if item.id.nil? || item.title.nil?

    # Title should truncate to 32 characters and append "/ *12345*"
    title = "#{item.title[0..31]} / *#{item.id}*"

    # Illiad encodes strings in Windows-1252, but Voyager SIP requires all messages be ASCII.
    if item.class.to_s == 'Source::Illiad'
      title = Iconv.iconv('ASCII//IGNORE', 'Windows-1252', title).join
    end
    # Illiad encodes strings in Windows-1252, but Voyager SIP requires all messages be ASCII.
    
    Voyager::SipClient.new(CONFIG['sip']['host'], CONFIG['sip']['port']) do |sip|
      sip.login(CONFIG['sip']['username'], CONFIG['sip']['password'], CONFIG['sip']['location']) do |response|
        # First be sure that an item doesn't already exist.
        sip.item_status(item.id) do |item_status|
          unless item_status[:AF] == 'Item barcode not found.  Please consult library personnel for assistance.'
            # Item already exists
            return Target::Voyager.new(:id => item.id,
                                       :title => item_status[:AJ],
                                       :due_date => item_status[:AH],
                                       :charged => !item_status[:AH].empty?)
          else
            # Item doesn't exist
            sip.create_bib(CONFIG['sip']['operator'], title, item.id) do |response|
              # Bib/MFHD/Item created. Store values.
              #
              # Values must be stored in order to delete the items via SIP.
              # Note: Voyager does not return mfhd_id.
              Rails::logger.info "Successfully created item with barcode #{item.id}"
              return Target::Voyager.new(:id => item.id,
                                         :title => title,
                                         :due_date => nil,
                                         :charged => false)
            end
          end
        end
      end
    end
    nil
  end
  # End Target Interface

private
  attr_reader :charged
  attr_writer :id, :title, :due_date, :charged

  def due_date=(date)
    begin
      @due_date = DateTime.strptime(date, '%Y%m%d    %H%M%S')
    rescue
      @due_date = nil
    end
  end

  def initialize(attributes = {})
    @id = attributes[:id]
    @title = attributes[:title]
    @charged = attributes[:charged]
    due_date = attributes[:due_date]
  end
end
