#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  connectivity_plus
  desktop_drop
  firebase_core
  flutter_meedu_videoplayer
  fullscreen_window
  medea_flutter_webrtc
  medea_jason
  media_kit_libs_windows_video
  media_kit_video
  pasteboard
  pdfx
  permission_handler_windows
  rive_common
  screen_brightness_windows
  screen_retriever
  sentry_flutter
  share_plus
  url_launcher_windows
  win_toast
  window_manager
  windows_taskbar
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  media_kit_native_event_loop
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
