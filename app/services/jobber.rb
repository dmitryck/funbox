# frozen_string_literal: true

require 'active_support/time'
require 'eventmachine'

class Jobber
  @@periodic_jobs = []
  @@once_jobs = []

  def self.every(interval, &block)
    @@periodic_jobs << { interval: interval, block: block }
  end

  def self.every!(interval, em: true, &block)
    run_periodics!([{interval: interval, block: block}], em: em)
  end

  def self.at(time, &block)
    timer = (time - Time.now).seconds
    @@once_jobs << { timer: timer, block: block }
  end

  def self.at!(time, em: true, &block)
    timer = (time - Time.now).seconds
    run_onces!([{timer: timer, block: block}], em: em)
  end

  def self.run_all!(em: true)
    run_onces!(@@once_jobs, em: em)
    run_periodics!(@@periodic_jobs, em: em)
  end

  def self.run_onces!(jobs, em: true)
    unless jobs.empty?
      block = proc do
        for job in jobs
          eval <<-EOS
            EM.add_timer(#{job[:timer]}) do
              ObjectSpace._id2ref(#{job[:block].object_id}).()
            end
          EOS
        end
      end
      em ? EM.run(&block) : block.()
    end
    ctrl_c
  end

  def self.run_periodics!(jobs, em: true)
    unless jobs.empty?
      block = proc do
        for job in jobs
          eval <<-EOS
            EM.add_periodic_timer(#{job[:interval]}) do
              ObjectSpace._id2ref(#{job[:block].object_id}).()
            end
          EOS
        end
      end
      em ? EM.run(&block) : block.()
    end
    ctrl_c
  end

  def self.ctrl_c
    trap "SIGINT" do
      puts "exiting #{self}.."
      exit 130
    end
  end
end
