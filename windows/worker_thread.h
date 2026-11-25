#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_WORKER_THREAD_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_WORKER_THREAD_H_

#include <condition_variable>
#include <deque>
#include <functional>
#include <mutex>
#include <thread>

namespace mobile_scanner {

// A background thread that runs posted tasks in order. COM is initialized
// (multithreaded) on the thread, so tasks can use WIC.
class WorkerThread {
 public:
  WorkerThread();
  // Waits for the running task to finish. Tasks that have not started yet
  // are discarded.
  ~WorkerThread();

  WorkerThread(const WorkerThread&) = delete;
  WorkerThread& operator=(const WorkerThread&) = delete;

  void Post(std::function<void()> task);

 private:
  void Run();

  std::mutex mutex_;
  std::condition_variable condition_;
  std::deque<std::function<void()>> tasks_;
  bool stopping_ = false;
  std::thread thread_;
};

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_WORKER_THREAD_H_
