module Put
  # Color yellow
  def self.warn(msg)
    STDOUT.puts "\e[33m#{msg}\e[0m"
  end

  # Color gray
  def self.info(msg)
    STDOUT.puts "\e[37m#{msg}\e[0m"
  end

  # Color green
  def self.success(msg)
    STDOUT.puts "\e[32m#{msg}\e[0m"
  end

  # Color red
  def self.error(msg)
    STDOUT.puts "\e[31m#{msg}\e[0m"
  end
end