# Functions dealing with hook scripts

# True if script starts with #!/bin/bash
# --------------------------------------
def shebang?(bash_hook)
  text = File.open(bash_hook).read
  text.gsub!(/\r\n?/, "\n")
  line = text.next
  return true if line.start_with? '#!/bin/bash'
  true if line.start_with? '#!/usr/bin/env bash'
end

# Handle hook scripts or normal files: returns path to file to provision
# ----------------------------------------------------------------------
def hook_handler(hook)
  # hook might be the upload file or an executable to give the path to the
  # file to be provisioned. Builders can use this to hook into the
  # provisioning process for new snaps and management templates.
  unless File.executable?(hook)
    puts '[WARNING] hook script ' + hook + ' not executable. Abandoning launch.'
    return nil
  end

  fext = File.extname(hook)
  if fext == '.sh' && shebang?(hook)
    `#{hook}`.strip # executes and returns output (should be file)
  # elsif fext == '.bat'
  #   return `#{hook}`.strip # executes and returns output (should be file)
  else
    # raise '[WARNING] hook script not valid bash .sh or .bat. Abandoning launch.'
    raise '[WARNING] hook script not valid bash file with .sh extension. Abandoning launch.'
  end
end

# TODO: Match extension to OS and pick appropriately if
# both a .bat and .sh are present.

# If arg is nil check for presence of snap_hook.${ext}
# ----------------------------------------------------
def snap_handler(hook)
  if hook.nil?
    %w[.sh .bat].each do |e|
      return hook_handler('./snap_hook' + e) if File.exist?('./snap_hook' + e)
    end
    return nil
  end
  hook_handler(hook)
end

# if arg is nil check for presence of management_hook.${ext}
# ----------------------------------------------------
def management_handler(hook)
  if hook.nil?
    %w[.sh .bat].each do |e|
      if File.exist?('./management_hook' + e)
        return hook_handler('management_hook' + e)
      end
    end
    return nil
  end
  hook_handler(hook)
end