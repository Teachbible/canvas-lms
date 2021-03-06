module Delayed

class TimeoutError < RuntimeError; end

class Worker

  Settings = [ :max_run_time, :max_attempts ]
  cattr_accessor :queue, *Settings

  self.max_attempts = 15
  self.max_run_time = 4.hours
  self.queue = "canvas_queue"

  attr_reader :config, :queue, :min_priority, :max_priority, :sleep_delay

  # Callback to fire when a delayed job fails max_attempts times. If this
  # callback is defined, then the value of destroy_failed_jobs is ignored, and
  # the job is destroyed if this block returns true.
  #
  # This allows for destroying "uninteresting" failures, while keeping around
  # interesting failures to be investigated later.
  #
  # The block is called with args(job, last_exception)
  def self.on_max_failures=(block)
    @@on_max_failures = block
  end
  cattr_reader :on_max_failures

  def initialize(options = {})
    @exit = false
    @config = options
    @parent_pid = options[:parent_pid]
    @queue = options[:queue] || self.class.queue
    @min_priority = options[:min_priority]
    @max_priority = options[:max_priority]
    @max_job_count = options[:worker_max_job_count].to_i
    @max_memory_usage = options[:worker_max_memory_usage].to_i
    @job_count = 0
  end

  def name=(name)
    @name = name
  end

  def name
    @name ||= "#{Socket.gethostname rescue "X"}:#{Process.pid}"
  end

  def set_process_name(new_name)
    $0 = "delayed:#{new_name}"
  end

  def exit?
    @exit || parent_exited?
  end

  def parent_exited?
    @parent_pid && @parent_pid != Process.ppid
  end

  def start
    say "Starting worker", :info

    trap('INT') { say 'Exiting'; @exit = true }

    loop do
      run
      break if exit?
    end

    say "Stopping worker", :info
  rescue => e
    Rails.logger.fatal("Child process died: #{e.inspect}") rescue nil
    ErrorReport.log_exception(:delayed_jobs, e) rescue nil
  ensure
    Delayed::Job.clear_locks!(name)
  end

  def run
    # need to do this here, since we're avoiding db calls in the master process pre-fork
    @sleep_delay ||= Setting.get_cached('delayed_jobs_sleep_delay', '5.0').to_f

    job = Delayed::Job.get_and_lock_next_available(
      name,
      self.class.max_run_time,
      queue,
      min_priority,
      max_priority)

    if job
      perform(job)

      @job_count += 1
      if @max_job_count > 0 && @job_count >= @max_job_count
        say "Max job count of #{@max_job_count} exceeded, dying"
        @exit = true
      end

      if @max_memory_usage > 0
        memory = Canvas.sample_memory
        if memory > @max_memory_usage
          say "Memory usage of #{memory} exceeds max of #{@max_memory_usage}, dying"
          @exit = true
        else
          say "Memory usage: #{memory}"
        end
      end
    else
      set_process_name("wait:#{@queue}:#{min_priority || 0}:#{max_priority || 'max'}")
      sleep(sleep_delay)
    end
  end

  def perform(job)
    set_process_name("run:#{job.id}:#{job.name}")
    say_job(job, "Processing #{log_job(job, :long)}", :info)
    runtime = Benchmark.realtime do
      Timeout.timeout(self.class.max_run_time.to_i, Delayed::TimeoutError) { job.invoke_job }
      Delayed::Stats.job_complete(job, self)
      Rails.logger.silence do
        job.destroy
      end
    end
    say_job(job, "Completed #{log_job(job)} %.0fms" % (runtime * 1000), :info)
  rescue Exception => e
    handle_failed_job(job, e)
  end

  def handle_failed_job(job, error)
    job.last_error = error.message + "\n" + error.backtrace.join("\n")
    say_job(job, "Failed with #{error.class} [#{error.message}] (#{job.attempts} attempts)", :error)
    reschedule(job, error)
  end

  # Reschedule the job in the future (when a job fails).
  # Uses an exponential scale depending on the number of failed attempts.
  def reschedule(job, error = nil, time = nil)
    job.attempts += 1
    if job.attempts >= (job.max_attempts || self.class.max_attempts)
      destroy_job = true
      if self.class.on_max_failures
        destroy_job = self.class.on_max_failures.call(job, error)
      end

      if destroy_job
        say_job(job, "destroying job because of #{job.attempts} failures", :info)
        job.destroy
      else
        job.fail!
      end
    else
      time ||= job.reschedule_at
      job.run_at = time
      job.unlock
      job.save!
    end
  end

  def say(msg, level = :debug)
    Rails.logger.send(level, "[#{Process.pid}]W #{msg}")
  end

  def say_job(job, msg, level = :debug)
    say("job_id:#{job.id} #{msg}", level)
  end

  def log_job(job, format = :short)
    case format
    when :long
      "#{job.full_name} #{ job.to_json(:include_root => false, :only => %w(priority attempts created_at max_attempts)) }"
    else
      job.full_name
    end
  end

end
end
