#include "worker_thread.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <objbase.h>

#include <utility>

namespace mobile_scanner {

WorkerThread::WorkerThread() : thread_(&WorkerThread::Run, this) {}

WorkerThread::~WorkerThread() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    stopping_ = true;
    tasks_.clear();
  }
  condition_.notify_one();
  thread_.join();
}

void WorkerThread::Post(std::function<void()> task) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    tasks_.push_back(std::move(task));
  }
  condition_.notify_one();
}

void WorkerThread::Run() {
  const HRESULT co_init = CoInitializeEx(nullptr, COINIT_MULTITHREADED);

  while (true) {
    std::function<void()> task;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      condition_.wait(lock, [this] { return stopping_ || !tasks_.empty(); });
      if (stopping_) {
        break;
      }
      task = std::move(tasks_.front());
      tasks_.pop_front();
    }
    task();
  }

  if (SUCCEEDED(co_init)) {
    CoUninitialize();
  }
}

}  // namespace mobile_scanner
