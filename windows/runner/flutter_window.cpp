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

    result += L"\\IT ENGINEERING MANAGEMENT INC\\Gapopa";
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
  int crtFd = -1;
};

static TeePipe CreateTeeForStdHandle(DWORD stdHandleId, FILE *crtStream) {
  TeePipe pipe;

  SECURITY_ATTRIBUTES sa{};
  sa.nLength = sizeof(sa);
  sa.bInheritHandle = TRUE;

  if (!CreatePipe(&pipe.readEnd, &pipe.writeEnd, &sa, 0))
    return pipe;

  pipe.originalHandle = GetStdHandle(stdHandleId);

  // Create CRT fd from pipe write handle
  int pipeFd = _open_osfhandle((intptr_t)pipe.writeEnd, _O_WRONLY | _O_TEXT);
  if (pipeFd == -1)
    return pipe;

  // Duplicate into stdout/stderr fd
  _dup2(pipeFd, _fileno(crtStream));
  pipe.crtFd = pipeFd;

  // Update Win32 std handle too (important for some libs)
  SetStdHandle(stdHandleId, pipe.writeEnd);

  // Disable buffering
  setvbuf(crtStream, nullptr, _IONBF, 0);

  return pipe;
}

static void StartForwardingThread(HANDLE pipeReadEnd, HANDLE logFileHandle,
                                  HANDLE originalStdHandle) {
  std::thread([=]() {
    std::vector<char> buffer(4096);

    while (true) {
      DWORD bytesRead = 0;
      BOOL ok = ReadFile(pipeReadEnd, buffer.data(), (DWORD)buffer.size(),
                         &bytesRead, nullptr);

      if (!ok || bytesRead == 0)
        break;

      DWORD written = 0;

      // Write to log
      WriteFile(logFileHandle, buffer.data(), bytesRead, &written, nullptr);

      // Write back to original console
      WriteFile(originalStdHandle, buffer.data(), bytesRead, &written, nullptr);
    }
  }).detach();
}

static void RedirectStdOutErrToLogFile() {
  std::wstring logPath = GetLogFilePath();

  HANDLE logFile = CreateFileW(logPath.c_str(), FILE_APPEND_DATA,
                               FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                               OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);

  if (logFile == INVALID_HANDLE_VALUE)
    return;

  // STDOUT
  TeePipe stdoutPipe = CreateTeeForStdHandle(STD_OUTPUT_HANDLE, stdout);
  StartForwardingThread(stdoutPipe.readEnd, logFile, stdoutPipe.originalHandle);

  // STDERR
  TeePipe stderrPipe = CreateTeeForStdHandle(STD_ERROR_HANDLE, stderr);
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
