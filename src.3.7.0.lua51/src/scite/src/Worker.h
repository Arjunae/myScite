// SciTE - Scintilla based Text Editor
/** @file Worker.h
 ** Definition of classes to perform background tasks as threads.
 **/
// Copyright 2011 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

struct Worker {
private:
	Mutex *mutex;
	volatile bool completed;
	volatile bool cancelling;
	volatile int jobSize;
	volatile int jobProgress;
public:
	Worker() : mutex(Mutex::Create()), completed(false), cancelling(false), jobSize(1), jobProgress(0) {
	}
	virtual ~Worker() {
		delete mutex;
	}
	virtual void Execute() {}
	bool FinishedJob() const {
		Lock lock(mutex);
		return completed;
	}
	void SetCompleted() {
		Lock lock(mutex);
		completed = true;
	}
	bool Cancelling() const {
		Lock lock(mutex);
		return cancelling;
	}
	int SizeJob() const {
		Lock lock(mutex);
		return jobSize;
	}
	void SetSizeJob(int size) {
		Lock lock(mutex);
		jobSize = size;
	}
	int ProgressMade() const {
		Lock lock(mutex);
		return jobProgress;
	}
	void IncrementProgress(int increment) {
		Lock lock(mutex);
		jobProgress += increment;
	}
	virtual void Cancel() {
		{
			Lock lock(mutex);
			cancelling = true;
		}
		// Wait for writing thread to finish
		for (;;) {
			Lock lock(mutex);
			if (completed)
				return;
		}
	}
};

struct WorkerListener {
	virtual void PostOnMainThread(int cmd, Worker *pWorker) = 0;
};
