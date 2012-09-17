require 'em-zeromq'

MSG_COUNT = 100_000

ctx = EM::ZeroMQ::Context.new(1)

class ZmqHandler
  def initialize
    @count = 0
    @expected = (1..MSG_COUNT).to_a
    @received = []
  end
  
  def on_readable(socket, parts)
    copied_parts = parts.map(&:copy_out_string)
    message = copied_parts.last
    @received << message.to_i
    #puts "Received message: #{message}"
    # @remaining.delete(copied_parts.last.to_i)

    @count += 1
    puts "#{@count} messages received so far. Latest one was: #{message}" if @count % 1_000 == 0
    
    if @count == MSG_COUNT
      diff = @expected - @received
      
      if diff.empty?
        puts "SUCCESS!"
      else
        puts "FAIL! Missing messages: #{diff.inspect}"
      end
      
      EM.stop
    end
  end
end

trap('INT') { EM.stop }
trap('QUIT') { EM.stop }

EM.run {
  EM.add_periodic_timer(0.5) do
    puts 'EM heartbeat...'
  end

  socket = ctx.socket(ZMQ::ROUTER, ZmqHandler.new)
  socket.identity = 'router'
  socket.setsockopt(ZMQ::HWM, 10)
  #socket.setsockopt(ZMQ::SWAP, 1*1_024*1_024)
  puts ">>> HWM: #{socket.getsockopt(ZMQ::HWM)}"
  socket.bind('tcp://127.0.0.1:9000')
}
