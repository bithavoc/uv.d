import duv.core;
import std.stdio;
import std.conv;
import std.concurrency;
import core.time;
import std.algorithm;
import std.exception;
alias std.concurrency.send stdsend;

alias void delegate() localJobsReceiveCallback;

localJobsReceiveCallback receiveCallbacks[TypeInfo_Class];
abstract class DuvThread {
  private:
      DuvLoop _loop;
      Tid _tid;
  public:
    
    this(DuvLoop loop) {
      _loop = loop;
    }

    @property DuvLoop loop() {
      return _loop;
    }

    @property Tid tid() {
      return _tid;
    }
    protected @property void tid(Tid tid) {
      _tid = tid;
    }

    void send(T...) (T vals) {
      stdsend(tid, vals);
    }

    //abstract void stop();
}

DuvThread duvSpawnThread(R, T...)(void function (Tid, T) exec, void delegate(DuvThread duvThread, R) res, T args) {
  //void delegate (DuvThread) removeJobCb;
  class runJob : DuvThread {
  package:
    void delegate(DuvThread thread, R ) callback;
    //runJob parentJobs[Tid];
    public:
      this(DuvLoop loop) {
        super(loop);
        callback = res;
        tid = spawn(exec, thisTid, args);
      }
        /*
      void stop() {
        if(parentJobs) {
          //parentJobs.remove(this.tid);
          parentJobs = null;
        }
      }*/
  }
  
  static runJob localJobs[Tid];
  /*removeJobCb = (thread) {
    localJobs.remove(thread.tid);
  };*/
  runJob job = new runJob(defaultLoop);
  localJobs[job.tid] = job;
  //job.parentJobs = localJobs;

  TypeInfo_Class runJobType = typeid(runJob);
  if(!receiveCallbacks.get(runJobType, null)) {
    receiveCallbacks[runJobType] = () {
      writeln("receiveTimeput");
      bool was = receiveTimeout(dur!"msecs"(1), (Tid sourceTid, R r) {
          runJob job = localJobs.get(sourceTid, null);
          if(job) {
            job.callback(job, r);
          }
          else {
            writeln("Job not found, wtf is going on?");
          }
          writeln("_receive received");
      });
      writeln("receiveTimeout ", was);
    };
  }
  return job;
}

void main() {
  writeln("Reading");
  runMainDuv((loop) {
    auto asyncPrepare = new DuvPrepare(loop);
    asyncPrepare.callback = (prepare) {
      writeln("Executing preprare");
      foreach(jobTypeCallback; receiveCallbacks.values) {
          jobTypeCallback();
          //job = null;
      }
    };
    asyncPrepare.start();
    auto forever = new DuvTimer(loop);
    forever.callback = (timer) {
      writeln("Timer Executed");
    };
    forever.setRepeat(200);
    forever.start();

    auto jobCreatorTimer = new DuvTimer(loop);
    int jobsCount = 0;
    jobCreatorTimer.callback = (timer) {
      if(jobsCount++ == 3) {
        timer.stop();
        //return;
      }
      int jobId = jobsCount;
      //writeln("Spawning new Thread ", jobsCount);

      auto job = duvSpawnThread(function void(Tid sender, int jobId) {
        for(;;) {
          //writeln("Receiveing inside Thread ", jobId);
          auto input= receiveOnly!(int);
          writefln("Thread %s Received %s", jobId, input);
          sender.send(thisTid, input);
        }
      }, (job, int workerJobId) {
        writefln("=>>>> Thread Callback %s value from thread worker %s", jobId, workerJobId);
        enforce(jobId == workerJobId);
      }, jobId);
     
      int jobId2 = jobId + 2;
      auto job2 = duvSpawnThread(function void(Tid sender, int jobId) {
        for(;;) {
          //writeln("Receiveing inside Thread ", jobId);
          auto input= receiveOnly!(int);
          writefln("Thread %s Received %s", jobId, input);
          sender.send(thisTid, input);
        }
      }, (job, int workerJobId) {
        writefln("=>>>> Thread (By 2) Callback %s value from thread worker %s", jobId2, workerJobId);
        enforce(jobId2 == workerJobId);
      }, jobId2);
      
      auto senderTimer = new DuvTimer(loop);
      senderTimer.callback = (timer) {
        writefln("Sending to Worker %s", jobId);
        job.send(jobId);
        job2.send(jobId2);
        //senderTimer.stop();
      };
      senderTimer.setTimeout(500);
      senderTimer.setRepeat(500);
      senderTimer.start();
    };
    jobCreatorTimer.setRepeat(400);
    jobCreatorTimer.start();
    //job.perform();
  });
}
