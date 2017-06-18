class Meiko::Event
  Numerics = {
    1   => :RPL_WELCOME,
    2   => :RPL_YOURHOST,
    3   => :RPL_CREATED,
    4   => :RPL_MYINFO,
    5   => :RPL_ISUPPORT,
    42  => :RPL_YOURID,
    250 => :RPL_STATSCONN,
    251 => :RPL_LUSERCLIENT,
    252 => :RPL_LUSEROP,
    253 => :RPL_LUSERUNKNOWN,
    254 => :RPL_LUSERCHANNELS,
    255 => :RPL_LUSERME,
    265 => :RPL_LOCALUSERS,
    266 => :RPL_GLOBALUSERS,
    332 => :RPL_TOPIC,
    333 => :RPL_TOPICWHOTIME,
    353 => :RPL_NAMEREPLY,
    366 => :RPL_ENDOFNAMES,
    372 => :RPL_MOTD,
    375 => :RPL_MOTDSTART,
    376 => :RPL_ENDOFMOTD}

  def initialize(raw, config)
    @config = config
    @raw = Meiko::EventRaw.new
    parse raw
  end

  def parse(raw)
    parts = raw.strip.split(' ', 4).reject{|x| x.empty?}

    if parts.first =~ /^:/
      @raw.prefix = parts.shift.sub(/^:/, '')
    end

    if parts.length == 1
      @raw.command = parts.shift
    elsif parts.length == 2
      @raw.command = parts.shift
      @raw.body    = parts.shift.sub(/^:/, '')
    elsif parts.length == 3
      @raw.command = parts.shift
      @raw.target  = parts.shift
      @raw.body    = parts.shift.sub(/^:/, '')
    end

    @raw.raw = raw.strip
  end

  def cmd
    unless @cmd
      if @raw.command =~ /^[0-9]+$/
        numeric = @raw.command.to_i

        if Meiko::Event::Numerics.has_key?(numeric)
          @cmd = Meiko::Event::Numerics[numeric]
        else
          @cmd = numeric
        end
      else
        @cmd = @raw.command.upcase.to_sym
      end
    end

    @cmd
  end

  def user
    unless @user
      @user = {}

      matches = /^(?<nickname>[^!]+)!(?<username>[^@]+)@(?<host>.+)$/.match(@raw.prefix)
      if matches
        @user[:host]     = matches[:host]
        @user[:nickname] = matches[:nickname]
        @user[:username] = matches[:username]
      end
    end

    @user
  end

  def from
    return user[:nickname] if @raw.target == @config[:nickname]

    @raw.target
  end

  def to_self
    from == @user[:nickname]
  end

  def msg
    @raw.body
  end

  def raw
    @raw
  end
end
