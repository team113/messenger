#include "flutter_window.h"

#include <cstdio>
#include <fcntl.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <io.h>
#include <shlobj.h>
#include <thread>
#include <vector>
#include <windows.h>

#include "flutter/generated_plugin_registrant.h"

static std::wstring GetLogFilePath() {
  PWSTR rawPath = nullptr;
  std::wstring result;

  if (SUCCEEDED(
          SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &rawPath))) {
    result = rawPath;
    CoTaskMemFree(rawPath);

    result += L"\\Gapopa";
    CreateDirectoryW(result.c_str(), nullptr); // ok if already exists

    result += L"\\app.log";
  } else {
    // Nuclear fallback: current directory
    result = L"app.log";
  }

  return result;
}

struct TeePipe {
  HANDLE readEnd = nullptr;
  HANDLE writeEnd = nullptr;
  HANDLE originalHandle = nullptr;
};

static TeePipe CreateTeePipeForStdHandle(DWORD stdHandleId) {
  TeePipe pipe;

  SECURITY_ATTRIBUTES sa{};
  sa.nLength = sizeof(sa);
  sa.bInheritHandle = true;

  // Create an anonymous pipe
  if (!CreatePipe(&pipe.readEnd, &pipe.writeEnd, &sa, 0))
    return pipe;

  // Save the original console handle
  pipe.originalHandle = GetStdHandle(stdHandleId);

  // Replace stdout/stderr with the pipe's write end
  SetStdHandle(stdHandleId, pipe.writeEnd);

  // Also update the CRT layer (_write, printf, etc.)
  int osHandle = _open_osfhandle((intptr_t)pipe.writeEnd, _O_TEXT);
  int targetFd =
      (stdHandleId == STD_OUTPUT_HANDLE) ? _fileno(stdout) : _fileno(stderr);
  _dup2(osHandle, targetFd);

  // Disable buffering for immediate flush behavior
  if (stdHandleId == STD_OUTPUT_HANDLE)
    setvbuf(stdout, nullptr, _IONBF, 0);
  else
    setvbuf(stderr, nullptr, _IONBF, 0);

  return pipe;
}

static void StartForwardingThread(HANDLE pipeReadEnd, HANDLE logFileHandle,
                                  HANDLE originalStdHandle) {
  std::thread([=]() {
    std::vector<char> buffer(4096);

    while (true) {
      DWORD bytesRead = 0;
      if (!ReadFile(pipeReadEnd, buffer.data(), (DWORD)buffer.size(),
                    &bytesRead, nullptr)) {
        break;
      }

      if (bytesRead == 0)
        break;

      DWORD bytesWritten = 0;

      // Write to log file
      WriteFile(logFileHandle, buffer.data(), bytesRead, &bytesWritten,
                nullptr);

      // Write back to original stdout/stderr
      WriteFile(originalStdHandle, buffer.data(), bytesRead, &bytesWritten,
                nullptr);
    }
  }).detach();
}

static void RedirectStdOutErrToLogFile() {
  std::wstring logPath = GetLogFilePath();

  HANDLE logFile = CreateFileW(logPath.c_str(), FILE_WRITE_DATA,
                               FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                               OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);

  if (logFile == INVALID_HANDLE_VALUE)
    return;

  // STDOUT
  TeePipe stdoutPipe = CreateTeePipeForStdHandle(STD_OUTPUT_HANDLE);
  StartForwardingThread(stdoutPipe.readEnd, logFile, stdoutPipe.originalHandle);

  // STDERR
  TeePipe stderrPipe = CreateTeePipeForStdHandle(STD_ERROR_HANDLE);
  StartForwardingThread(stderrPipe.readEnd, logFile, stderrPipe.originalHandle);

  printf("stdout/stderr redirected to %ls\n", logPath.c_str());
}

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(),
      "team113.flutter.dev/windows_utils",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<> &call,
         std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() == "redirectStdOut") {
          RedirectStdOutErrToLogFile();
          result->Success(0);
        } else {
          result->NotImplemented();
        }
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
  case WM_FONTCHANGE:
    flutter_controller_->engine()->ReloadSystemFonts();
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
