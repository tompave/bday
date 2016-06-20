require 'pstore'
require 'digest/md5'

class Person
  class << self
    def all
      db.transaction(true) do
        db.roots.map { |key| db[key].to_h }
                .sort_by { |h| h[:name].downcase }
      end
    end

    def find(name)
      db.transaction(true) do
        db[name]
      end
    end

    def rsvp(name:, coming:, secret:)
      new(name, coming, secret).save
    end

    def db
      @db ||= PStore.new("bday.pstore")
    end

    def digest(str)
      Digest::MD5.hexdigest(str)
    end
  end

  attr_writer :coming

  def initialize(name, coming, secret)
    @name = name
    @coming = coming
    @secret = digest(secret)
  end

  def save
    return false unless (@name && @coming && @secret)
    self.class.db.transaction do |db|
      db[@name] = self
    end
  end

  def delete
    self.class.db.transaction do |db|
      db.delete(@name)
    end
  end

  def can_update?(secret)
    @secret == digest(secret)
  end

  def to_h(with_secret=false)
    h = { name: @name, coming: @coming }
    h[:secret] = @secret if with_secret
    h
  end

  private

  def digest(str)
    self.class.digest(str)
  end
end
