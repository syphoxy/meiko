require 'pp'
require 'socket'

class Meiko::Instance
  def initialize(opts = {})
    @hooks  = {}
    @config = get_config opts

    # Establish connection
    @socket = TCPSocket.new(@config[:connection][:host], @config[:connection][:port])
    if @config[:connection][:password]
      @socket.print "PASS #{@config[:password]}\r\n"
    end

    # User registration
    # TODO nick collision code!
    @socket.print "NICK #{@config[:registration][:nickname]}\r\n"
    @socket.print "USER #{@config[:registration][:username]} #{@config[:registration][:mode]} #{@config[:registration][:unused]} :#{@config[:registration][:realname]}\r\n"

    # default event hooks
    hook(:PING) { |_, e| send :PONG, body: e.msg }

    # these are pre-registration hooks
    hook(:PRIVMSG, tag: :pre_reg) { |_, e| puts "(server) #{e.raw.prefix}: #{e.msg}" }
    hook(:NOTICE, tag: :pre_reg) { |_, e| puts "(notice) #{e.raw.prefix}: #{e.msg}" }

    # this is post-registration hook
    hook :RPL_WELCOME, repeat: :never do
      # remove our pre-registration hooks
      remove_hooks :PRIVMSG, :pre_reg
      remove_hooks :NOTICE, :pre_reg

      # add new PRIVMSG hook
      hook :PRIVMSG, tag: :verbose do |params, event|
        if event.from == event.user[:nickname]
          puts "#{event.from}: #{event.msg}"
        elsif event.user[:nickname]
          puts "(#{event.from}) #{event.user[:nickname]}: #{event.msg}"
        end
      end
      
      # add new NOTICE hook
      hook :NOTICE, tag: :verbose do |params, event|
        if event.from == event.user[:nickname]
          puts "(notice) #{event.from}: #{event.msg}"
        elsif event.user[:nickname]
          puts "(#{event.from}) (notice) #{event.user[:nickname]}: #{event.msg}"
        end
      end

      hook :PRIVMSG do |params, event|
        if event.msg[0] == "!"
          command, args = event.msg.split(/\s+/, 2)
          command = command[1..-1].downcase
          args = args.split(/\s+/)
          
          if command == "quit"
            send :QUIT
          elsif @commands[command]
            @commands[command].call(args, params, event)
          end
        end
      end

      # join our configured initial channels
      join @config[:settings][:channels], @config[:settings][:keys]
    end
  end

  def send(command, spec = {})
    spec = spec.clone

    spec[:body] = ":#{spec[:body]}" if spec[:body]

    @socket.print "#{spec[:prefix]} #{command} #{spec[:target]} #{spec[:body]}\r\n"
  end

  def join(channels, keys, &block)
    channels = channels.clone
    keys = keys.clone

    send :JOIN, target: "#{channels.join(",")} #{keys.join(",")}"

    if block_given?
      hook :RPL_TOPIC, repeat: :never, params: {target: $1, block: block} do |params, event|
        if params[:target] == event.msg.split(" :", 2).first
          params[:block].call(params, event)
          next
        end
      end
    end
  end

  # should this have a hook?
  def part(channels, reason = nil, &block)
    channels = channels.clone
    reason = reason.clone

    send :PART, target: "#{channels.join(",")} #{reason}"
  end

  def command(cmd, &block)
    @commands ||= {}
    @commands[cmd] = block
  end

  def hook(event, opts = {}, &block)
    return unless event && block_given?

    opts = opts.clone

    @hooks[event] ||= []
    @hooks[event] << {
      tag: opts[:tag],
      repeat: opts[:repeat],
      params: opts[:params],
      block: block
    }
  end

  def remove_hooks(event, tag)
    return unless event && tag

    @hooks[event] ||= []
    @hooks[event].delete_if { |e| e[:tag] == tag }
  end

  def get_config(config = {})
    config = config.clone

    config[:registration][:mode]   ||= "0"
    config[:registration][:unused] ||= "*"

    config
  end

  def tick
    raw = @socket.gets

    return unless @socket

    event = Meiko::Event.new(raw, @config)

    @hooks.clone.each do |name, hooks|
      next if name != event.cmd

      hooks.each_index do |j|
        hook = hooks[j]
        result = hook[:block].call(hook[:params], event)

        hooks.delete_at(j) if hook[:repeat] == :never
      end
    end
  end
end
