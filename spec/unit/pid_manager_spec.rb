# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Liquidbook::PidManager do
  let(:tmpdir) { Dir.mktmpdir }
  let(:manager) { described_class.new(theme_root: tmpdir) }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe "#pid_file_path" do
    it "returns the path under .liquid-preview/" do
      expect(manager.pid_file_path).to eq(File.join(tmpdir, ".liquid-preview", "server.pid"))
    end
  end

  describe "#write_pid / #read_pid" do
    it "writes and reads the current PID" do
      manager.write_pid
      expect(manager.read_pid).to eq(Process.pid)
    end

    it "creates the .liquid-preview directory if it does not exist" do
      manager.write_pid
      expect(File.directory?(File.join(tmpdir, ".liquid-preview"))).to be true
    end
  end

  describe "#read_pid" do
    it "returns nil when no PID file exists" do
      expect(manager.read_pid).to be_nil
    end

    it "returns nil for an empty PID file" do
      FileUtils.mkdir_p(File.join(tmpdir, ".liquid-preview"))
      File.write(manager.pid_file_path, "")
      expect(manager.read_pid).to be_nil
    end
  end

  describe "#remove_pid" do
    it "removes the PID file" do
      manager.write_pid
      manager.remove_pid
      expect(File.exist?(manager.pid_file_path)).to be false
    end

    it "does nothing when no PID file exists" do
      expect { manager.remove_pid }.not_to raise_error
    end
  end

  describe "#process_alive?" do
    it "returns true for the current process" do
      expect(manager.process_alive?(Process.pid)).to be true
    end

    it "returns false for a non-existent PID" do
      # Use a PID that is very unlikely to exist
      expect(manager.process_alive?(99999999)).to be false
    end
  end

  describe "#ensure_can_start!" do
    context "when no PID file exists" do
      it "returns :ok" do
        expect(manager.ensure_can_start!).to eq(:ok)
      end
    end

    context "when PID file has a stale PID" do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, ".liquid-preview"))
        File.write(manager.pid_file_path, "99999999")
      end

      it "removes the stale PID file and returns :stale_pid_cleaned" do
        expect(manager.ensure_can_start!).to eq(:stale_pid_cleaned)
        expect(File.exist?(manager.pid_file_path)).to be false
      end
    end

    context "when PID file has a living process" do
      before do
        manager.write_pid
      end

      it "raises an error" do
        expect { manager.ensure_can_start! }.to raise_error(
          Liquidbook::Error, /already running/
        )
      end
    end
  end

  describe "#stop!" do
    context "when no PID file exists" do
      it "returns :not_running" do
        expect(manager.stop!).to eq(:not_running)
      end
    end

    context "when PID file has a stale PID" do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, ".liquid-preview"))
        File.write(manager.pid_file_path, "99999999")
      end

      it "removes the stale PID file and returns :stale_pid_cleaned" do
        expect(manager.stop!).to eq(:stale_pid_cleaned)
        expect(File.exist?(manager.pid_file_path)).to be false
      end
    end

    context "when PID file has a living process" do
      let(:child_pid) { spawn("sleep 60") }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, ".liquid-preview"))
        File.write(manager.pid_file_path, child_pid.to_s)
      end

      after do
        Process.wait(child_pid) rescue nil
      end

      it "sends SIGTERM and returns :stopped" do
        expect(manager.stop!).to eq(:stopped)
        expect(File.exist?(manager.pid_file_path)).to be false
      end
    end
  end
end
