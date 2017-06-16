# frozen_string_literal: true

require 'spec_helper'

describe Que::Listener do
  let :listener do
    Que::Listener.new(pool: QUE_POOL)
  end

  let :connection do
    @connection
  end

  let :pid do
    connection.backend_pid
  end

  around do |&block|
    QUE_POOL.checkout do |conn|
      begin
        listener.listen
        @connection = conn

        super(&block)
      ensure
        listener.unlisten
      end
    end
  end

  def notify(payload)
    DB.notify "que_listener_#{pid}", payload: JSON.dump(payload)
  end

  it "should return messages to the locker in bulk by type"

  it "should pre-process new_job messages"

  it "should be resilient to messages that aren't invalid JSON"

  describe "unlisten" do
    it "should stop listening for new messages" do
      notify(message_type: 'blah')
      {} while connection.notifies

      listener.unlisten
      notify(message_type: 'blah')

      # Execute a new query to fetch any new notifications.
      connection.async_exec "SELECT 1"
      assert_nil connection.notifies
    end

    it "when unlistening should not leave any residual messages" do
      5.times { notify(message_type: 'blah') }

      listener.unlisten
      assert_nil connection.notifies

      # Execute a new query to fetch any remaining notifications.
      connection.async_exec "SELECT 1"
      assert_nil connection.notifies
    end
  end
end
