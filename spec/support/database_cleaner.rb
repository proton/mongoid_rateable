class DatabaseCleaner
  class << self
    def clean
      new.clean
    end
  end

  def clean
    if mongoid4?
      collections.each { |c| database[c].find.remove_all }
    else
      collections.each { |c| database[c].find.delete_many }
    end
  end

  private

  def mongoid4?
    Mongoid::VERSION.start_with? '4'
  end

  def database
    if mongoid4?
      Mongoid.default_session
    else
      Mongoid::Clients.default
    end
  end

  def collections
    database['system.namespaces'].find(name: { '$not' => /\.system\.|\$/ }).to_a.map do |collection|
      _, name = collection['name'].split('.', 2)
      name
    end
  end
end
