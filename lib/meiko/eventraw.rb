class Meiko::EventRaw
  def initialize(prefix = nil, command = nil, target = nil, body = nil, raw = nil)
    @prefix  = prefix
    @command = command
    @target  = target
    @body    = body
    @raw     = raw
  end

  def prefix
    @prefix
  end

  def prefix=(value)
    @prefix = value
  end

  def command
    @command
  end

  def command=(value)
    @command = value
  end

  def target
    @target
  end

  def target=(value)
    @target = value
  end

  def body
    @body
  end

  def body=(value)
    @body = value
  end

  def raw
    @raw
  end

  def raw=(value)
    @raw = value
  end
end
