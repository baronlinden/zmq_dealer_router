require 'em-zeromq'

MSG_COUNT = 100_000

ctx = EM::ZeroMQ::Context.new(1)

class ZmqHandler
  def on_readable(socket, parts)
  end
end

trap('INT') { EM.stop }
trap('QUIT') { EM.stop }

EM.run {
  socket = ctx.socket(ZMQ::DEALER, ZmqHandler.new)
  socket.identity = 'dealer'
  #socket.setsockopt(ZMQ::HWM, 1_000)
  #socket.setsockopt(ZMQ::SWAP, 10*1_024*1_024)
  puts ">>> HWM: #{socket.getsockopt(ZMQ::HWM)}"
  socket.connect('tcp://127.0.0.1:9000')
  
  start_time = Time.now.to_f
  
  for i in 1..MSG_COUNT do
    begin
      socket.send_msg('', i.to_s)
      #sleep(0.005) if i % 1_000 == 0
    rescue => e
      puts e.message
      puts "#{ZMQ::Util.errno}: #{ZMQ::Util.error_string}"
      puts "#{i - 1} messages were sent"
      exit!(0)
    end
  end
  
  end_time = Time.now.to_f
  duration = end_time - start_time
  rate = MSG_COUNT / duration
  
  puts "Test duration: #{duration.round(3)} seconds"
  puts "Sending rate: #{rate.round(2)} messages/sec"
  
  EM.stop
}
