require 'spec_helper'

describe "An additional job queue" do
  describe "in the public schema" do
    before do
      Que.create_job_queue!('my_job_queue')
    end

    after do
      DB.drop_table :my_job_queue
    end

    it "should be able to be queued to" do
      DB[:my_job_queue].count.should == 0
      Que::Job.enqueue(job_queue: 'my_job_queue')
      DB[:my_job_queue].select_map(:job_class).should == ['Que::Job']
    end
  end

  describe "in a non-public schema" do
    before do
      DB.create_schema(:que_jobs_schema)
      Que.create_job_queue!('que_jobs_schema.que_jobs')
    end

    after do
      DB.drop_schema(:que_jobs_schema, cascade: true)
    end

    it "should handle schema-qualified job queues" do
      DB[:que_jobs_schema__que_jobs].count.should == 0
      Que::Job.enqueue(job_queue: 'que_jobs_schema.que_jobs')
      DB[:que_jobs_schema__que_jobs].select_map(:job_class).should == ['Que::Job']
    end

    it "should respect the schema search path" do
      Que.pool.checkout do
        Que.execute "SET search_path TO que_jobs_schema"
        DB[:que_jobs_schema__que_jobs].count.should == 0
        Que::Job.enqueue
        DB[:que_jobs_schema__que_jobs].select_map(:job_class).should == ['Que::Job']
        Que.execute "RESET search_path"
      end
    end
  end
end
