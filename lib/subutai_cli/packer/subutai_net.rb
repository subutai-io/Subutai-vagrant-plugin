require 'socket'
require 'timeout'
require 'rbconfig'
require 'log4r'

# methods dealing with port management

# Checks if a port is not available
# ---------------------------------
def port_bound?(host, port)
  Timeout.timeout(1) do
    s = TCPSocket.new(host, port)
    s.close rescue nil
    return true
  end
rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, \
       Errno::ENETUNREACH, Errno::EACCES, Errno::ENOTCONN, \
       Errno::EADDRNOTAVAIL
  return false
end

# Finds free port for console and puts in wormstore
# -------------------------------------------------
def find_port(port)
  port += 1 while port_bound?('127.0.0.1', port)
  port
end

# Most hypervisors uses a mac prefix: we cannot just generate a random mac
PROVIDERS=%i[:virtualbox :libvirt :vmware_fusion :vmware :parallels :hyper_v]
PROVIDER_MAC_PREFIXES = {
    :virtualbox       => '080027',
    :libvirt          => '525400',
    :vmware_fusion    => '______',
    :vmware           => '______',
    :parallels        => '______',
    :hyper_v          => '______'
}

os = nil
os = :windows if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
os = :mac     if (RbConfig::CONFIG['host_os'] =~ /darwin/)
os = :linux   if (RbConfig::CONFIG['host_os'] =~ /linux/)

def broadcast_addr
  octets = `route print 0.0.0.0 | findstr 0.0.0.0`.split(' ').map(&:strip)[2].split('.')    \
    if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  octets = `ip route show | grep default | awk '{print $3}'`.gsub(/\s+/, "").split(".")     \
    if (RbConfig::CONFIG['host_os'] =~ /linux/)
  octets = `route -n get default | grep gateway | awk '{print $2}'`.gsub(/\s+/, "").split(".") \
    if (RbConfig::CONFIG['host_os'] =~ /darwin/)
  octets[3] = 255
  octets.join('.')
end

def broadcast_ping(count)
  system("ping -n #{count} #{broadcast_addr} >/dev/null")   \
    if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  system("ping -c #{count} #{broadcast_addr} >/dev/null")   \
    if (RbConfig::CONFIG['host_os'] =~ /darwin|linux/)
end

def zero_pad_mac(mac)
  reassembled = ''
  mac.split(':').each do |octet|
    octet = '0' + octet if octet.length == 1
    reassembled += octet
  end
  reassembled
end

def arp_table
  broadcast_ping(2)
  arp_table = {}
  `arp -a`.split("\n").each do |line|
    matches = /.*(\d+\.\d+\.\d+.\d+)[[:space:]]((([a-f]|[0-9]){1,2}:){5}([a-f]|[0-9]){1,2})[[:space:]].*/.match(line) \
      if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
    matches = /.*\((\d+\.\d+\.\d+.\d+)\) at ((([a-f]|[0-9]){1,2}:){5}([a-f]|[0-9]){1,2}) .*/.match(line) \
      if (RbConfig::CONFIG['host_os'] =~ /darwin|linux/)

    if ! matches.nil? && ! matches[2].nil?
      key_mac = zero_pad_mac(matches[2])
      value_ip = matches[1]
      arp_table.store(key_mac, value_ip)
    end
  end
  arp_table
end

def mac_uniq?(mac)
  arptab = arp_table
  arptab[mac].nil?
end

def find_mac(provider)
  mac = random_mac_addr(provider)
  until mac_uniq?(mac) do
    mac = random_mac_addr(provider)
  end
  mac
end

# Generate a random mac address that works with the hypervisor of a provider
def random_mac_addr(provider)
  symbol = provider.to_sym
  case symbol
    when :virtualbox
      PROVIDER_MAC_PREFIXES[:virtualbox] + 3.times.map { '%02x' % rand(0..255) }.join
    when :libvirt
      PROVIDER_MAC_PREFIXES[:libvirt] + 3.times.map { '%02x' % rand(0..255) }.join
    when :vmware_fusion
      # PROVIDER_MAC_PREFIXES[:vmware_fusion] + 3.times.map { '%02x' % rand(0..255) }.join
      raise "Unsupported provider #{provider}"
    when :vmware
      # PROVIDER_MAC_PREFIXES[:vmware] + 3.times.map { '%02x' % rand(0..255) }.join
      raise "Unsupported provider #{provider}"
    when :parallels
      # PROVIDER_MAC_PREFIXES[:parallels] + 3.times.map { '%02x' % rand(0..255) }.join
      raise "Unsupported provider #{provider}"
    when :hyper_v
      # PROVIDER_MAC_PREFIXES[:hyper_v] + 3.times.map { '%02x' % rand(0..255) }.join
    else
      raise "Unsupported provider #{provider}"
  end
end
