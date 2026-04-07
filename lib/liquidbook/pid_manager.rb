# frozen_string_literal: true

module Liquidbook
  class PidManager
    PID_FILE_NAME = "server.pid"

    def initialize(theme_root:)
      @theme_root = theme_root
    end

    def pid_file_path
      File.join(@theme_root, ".liquid-preview", PID_FILE_NAME)
    end

    # Write the current process PID to the PID file
    def write_pid
      dir = File.dirname(pid_file_path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      File.write(pid_file_path, Process.pid.to_s)
    end

    # Read the PID from the PID file, returns nil if not found
    def read_pid
      return nil unless File.exist?(pid_file_path)

      pid = File.read(pid_file_path).strip.to_i
      pid.positive? ? pid : nil
    end

    # Remove the PID file
    def remove_pid
      File.delete(pid_file_path) if File.exist?(pid_file_path)
    end

    # Check if a process with the given PID is alive
    def process_alive?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    rescue Errno::EPERM
      # Process exists but we don't have permission to signal it
      true
    end

    # Check the current state and ensure it's safe to start
    # Returns :ok, :stale_pid_cleaned, or raises an error
    def ensure_can_start!
      pid = read_pid
      return :ok if pid.nil?

      if process_alive?(pid)
        raise Error, "Server is already running (PID: #{pid}). Run `liquidbook stop` to stop it."
      end

      remove_pid
      :stale_pid_cleaned
    end

    # Stop the running server process
    # Returns :stopped, :not_running, or :stale_pid_cleaned
    def stop!
      pid = read_pid

      if pid.nil?
        return :not_running
      end

      unless process_alive?(pid)
        remove_pid
        return :stale_pid_cleaned
      end

      Process.kill("TERM", pid)
      remove_pid
      :stopped
    rescue Errno::EPERM
      raise Error, "Permission denied: cannot stop process (PID: #{pid})."
    end
  end
end
