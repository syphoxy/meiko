#!/usr/bin/env ruby

# example bot instance

require 'meiko'

instance = Meiko.instance({
  connection: {
    host: "irc.yourhost.com",
    port: 6667,
    password: nil
  },
  registration: {
    nickname: "MyBot",
    username: "MyBot",
    realname: "My Bot"
  },
  settings: {
    channels: ["#your_channel"],
    keys: [""],
    qmessages: ["しつれいします","では、また"],
    debug: true
  }
})

instance.command "bc" do |args, params, event|
  require 'haste'

  IO.popen("timeout 1 bc -lq", "r+") do |pipe|
    pipe.puts args.join(" ")
    pipe.close_write
    result = pipe.read

    if result =~ /\\$/
      instance.send :PRIVMSG, target: event.from, body: "#{args.join(" ")} = result is too big!"
    else
      instance.send :PRIVMSG, target: event.from, body: "#{args.join(" ")} = #{result.split("\n").join(", ").gsub(/[\n\r]/, "")}"
    end
  end
end

loop { instance.tick }
